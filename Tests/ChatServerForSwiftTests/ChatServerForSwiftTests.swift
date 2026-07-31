@testable import ChatServerForSwift
import VaporTesting
import Testing
import Vapor
import CryptoKit
import Foundation

@Suite("App Tests", .serialized)
struct ChatServerForSwiftTests {
    
    // 请求体结构
    struct RegisterRequest: Content {
        let username: String
        let organizationCode: String
        let publicKey: String
    }
    
    struct AuthChallengeRequest: Content {
        let username: String
    }
    
    struct AuthChallengeResponse: Content {
        let nonce: String
        let ephemeralPublicKey: String
    }
    
    struct MnemonicLoginRequest: Content {
        let username: String
        let nonce: String
        let proof: String
    }
    
    struct LoginResponse: Content {
        let token: String
        let id: String
        let username: String
        let nickname: String
        let organizationCode: String
        let createdAt: Date?
    }
    
    struct ChangeNicknameRequest: Content {
        let nickname: String
    }
    
    struct PublicKeyResponse: Content {
        let userID: String
        let publicKey: String?
    }
    
    struct UserResponse: Content {
        let id: String
        let username: String
        let nickname: String
        let organizationCode: String
        let createdAt: Date?
    }
    
    // MARK: - 辅助方法
    
    /// 客户端计算 proof = HMAC-SHA256(key: 共享密钥, data: nonce || username)
    private func computeProof(
        clientPrivateKey: Curve25519.KeyAgreement.PrivateKey,
        serverEphemeralPublicKeyBase64: String,
        nonce: String,
        username: String
    ) throws -> String {
        let serverEphPubData = Data(base64Encoded: serverEphemeralPublicKeyBase64)!
        let serverEphPub = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: serverEphPubData)
        let sharedSecret = try clientPrivateKey.sharedSecretFromKeyAgreement(with: serverEphPub)
        let key = SymmetricKey(data: sharedSecret.withUnsafeBytes { Data($0) })
        let message = Data((nonce + username).utf8)
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: key)
        return Data(mac).base64EncodedString()
    }
    
    private func registerUser(
        app: Application,
        username: String,
        publicKey: String,
        organizationCode: String = "ORG001"
    ) async throws -> String {
        let registerReq = RegisterRequest(
            username: username,
            organizationCode: organizationCode,
            publicKey: publicKey
        )
        var userID = ""
        try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
            try req.content.encode(registerReq)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            let user = try res.content.decode(UserResponse.self)
            userID = user.id
        })
        return userID
    }
    
    /// 助记词登录，返回会话 token
    private func login(
        app: Application,
        username: String,
        clientPrivateKey: Curve25519.KeyAgreement.PrivateKey
    ) async throws -> String {
        var nonce = ""
        var ephPubB64 = ""
        let challengeReq = AuthChallengeRequest(username: username)
        try await app.testing().test(.POST, "api/v1/auth/challenge", beforeRequest: { req in
            try req.content.encode(challengeReq)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            let challenge = try res.content.decode(AuthChallengeResponse.self)
            nonce = challenge.nonce
            ephPubB64 = challenge.ephemeralPublicKey
        })
        
        let proof = try computeProof(
            clientPrivateKey: clientPrivateKey,
            serverEphemeralPublicKeyBase64: ephPubB64,
            nonce: nonce,
            username: username
        )
        
        var token = ""
        let loginReq = MnemonicLoginRequest(username: username, nonce: nonce, proof: proof)
        try await app.testing().test(.POST, "api/v1/auth/login", beforeRequest: { req in
            try req.content.encode(loginReq)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            let login = try res.content.decode(LoginResponse.self)
            token = login.token
        })
        return token
    }
    
    // MARK: - 测试
    
    @Test("Test Health Check Route")
    func healthCheck() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "health", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "OK")
            })
        }
    }
    
    @Test("Test Register and Mnemonic Login")
    func registerAndLogin() async throws {
        try await withApp(configure: configure) { app in
            // 生成助记词派生的密钥对
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let publicKeyB64 = clientKey.publicKey.rawRepresentation.base64EncodedString()
            
            // 1. 注册（绑定公钥）
            let userID = try await registerUser(
                app: app,
                username: "mnemonicuser",
                publicKey: publicKeyB64
            )
            
            // 2. 助记词登录（挑战-响应）
            let token = try await login(
                app: app,
                username: "mnemonicuser",
                clientPrivateKey: clientKey
            )
            #expect(!token.isEmpty)
            
            // 3. 用 token 获取用户信息
            try await app.testing().test(.GET, "api/v1/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                #expect(user.id == userID)
                #expect(user.username == "mnemonicuser")
            })
            
            // 4. 无 token 访问被拒绝
            try await app.testing().test(.GET, "api/v1/profile", afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    @Test("Test Wrong Proof Rejected")
    func wrongProofRejected() async throws {
        try await withApp(configure: configure) { app in
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let publicKeyB64 = clientKey.publicKey.rawRepresentation.base64EncodedString()
            _ = try await registerUser(app: app, username: "wrongproof", publicKey: publicKeyB64)
            
            // 发起挑战
            var nonce = ""
            var ephPubB64 = ""
            try await app.testing().test(.POST, "api/v1/auth/challenge", beforeRequest: { req in
                try req.content.encode(AuthChallengeRequest(username: "wrongproof"))
            }, afterResponse: { res async throws in
                let challenge = try res.content.decode(AuthChallengeResponse.self)
                nonce = challenge.nonce
                ephPubB64 = challenge.ephemeralPublicKey
            })
            
            // 用错误的 proof（伪造密钥）登录
            let attackerKey = Curve25519.KeyAgreement.PrivateKey()
            let wrongProof = try computeProof(
                clientPrivateKey: attackerKey,
                serverEphemeralPublicKeyBase64: ephPubB64,
                nonce: nonce,
                username: "wrongproof"
            )
            
            try await app.testing().test(.POST, "api/v1/auth/login", beforeRequest: { req in
                try req.content.encode(MnemonicLoginRequest(
                    username: "wrongproof",
                    nonce: nonce,
                    proof: wrongProof
                ))
            }, afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    @Test("Test Change Nickname")
    func changeNickname() async throws {
        try await withApp(configure: configure) { app in
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let publicKeyB64 = clientKey.publicKey.rawRepresentation.base64EncodedString()
            _ = try await registerUser(app: app, username: "nickuser", publicKey: publicKeyB64)
            let token = try await login(app: app, username: "nickuser", clientPrivateKey: clientKey)
            
            let changeReq = ChangeNicknameRequest(nickname: "newnickname")
            try await app.testing().test(.POST, "api/v1/nickname", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
                try req.content.encode(changeReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let userResponse = try res.content.decode(UserResponse.self)
                #expect(userResponse.nickname == "newnickname")
            })
        }
    }
    
    @Test("Test Get Public Key")
    func getPublicKey() async throws {
        try await withApp(configure: configure) { app in
            // 用户 A
            let keyA = Curve25519.KeyAgreement.PrivateKey()
            let pubA = keyA.publicKey.rawRepresentation.base64EncodedString()
            let userAID = try await registerUser(app: app, username: "userA", publicKey: pubA)
            let tokenA = try await login(app: app, username: "userA", clientPrivateKey: keyA)
            
            // 用户 B
            let keyB = Curve25519.KeyAgreement.PrivateKey()
            let pubB = keyB.publicKey.rawRepresentation.base64EncodedString()
            let userBID = try await registerUser(app: app, username: "userB", publicKey: pubB)
            
            // A 获取 B 的公钥
            try await app.testing().test(.GET, "api/v1/keys/\(userBID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PublicKeyResponse.self)
                #expect(response.userID == userBID)
                #expect(response.publicKey == pubB)
            })
            
            // B 自己的公钥可从自身 token 获取（用于核对）
            _ = userAID
        }
    }
    
    @Test("Test Registration with Invalid Organization Code")
    func registerWithInvalidOrgCode() async throws {
        try await withApp(configure: configure) { app in
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let publicKeyB64 = clientKey.publicKey.rawRepresentation.base64EncodedString()
            let registerReq = RegisterRequest(
                username: "invalidorg",
                organizationCode: "INVALID",
                publicKey: publicKeyB64
            )
            
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("Test Registration with Invalid Public Key")
    func registerWithInvalidPublicKey() async throws {
        try await withApp(configure: configure) { app in
            let registerReq = RegisterRequest(
                username: "badkey",
                organizationCode: "ORG001",
                publicKey: "invalid-key"
            )
            
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
}

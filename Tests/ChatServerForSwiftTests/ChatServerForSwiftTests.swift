@testable import ChatServerForSwift
import VaporTesting
import Testing
import Vapor
import CryptoKit
import Foundation

@Suite("App Tests", .serialized)
struct ChatServerForSwiftTests {
    
    // 管理员引导密钥（测试环境由 configure 注入，与 configure.swift 一致）
    private let adminSecret = "test-admin-secret"
    
    // 请求体结构
    struct RegisterRequest: Content {
        let username: String
        let invitationCode: String
        let publicKey: String
    }
    
    struct AdminRegisterRequest: Content {
        let username: String
        let publicKey: String
        let adminSecret: String
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
        let role: String
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
        let role: String
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
    
    /// 通过管理员注册接口创建管理员，返回管理员用户ID
    private func createAdmin(
        app: Application,
        username: String,
        publicKey: String
    ) async throws -> String {
        let req = AdminRegisterRequest(
            username: username,
            publicKey: publicKey,
            adminSecret: adminSecret
        )
        var adminID = ""
        try await app.testing().test(.POST, "api/v1/admin/register", beforeRequest: { r in
            try r.content.encode(req)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            let user = try res.content.decode(UserResponse.self)
            #expect(user.role == "admin")
            adminID = user.id
        })
        return adminID
    }
    
    /// 管理员登录并生成一个邀请码，返回邀请码
    private func createInvitationCode(
        app: Application,
        adminToken: String,
        expiresAt: Date? = nil
    ) async throws -> String {
        var code = ""
        try await app.testing().test(.POST, "api/v1/admin/invitations", beforeRequest: { r in
            r.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            try r.content.encode(CreateInvitationRequest(expiresAt: expiresAt ?? Date().addingTimeInterval(7 * 24 * 60 * 60)))
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            let invitation = try res.content.decode(InvitationCodeDTO.self)
            code = invitation.code
        })
        return code
    }
    
    /// 创建管理员账号，登录并生成邀请码（返回邀请码和管理员token）
    private func adminCreateInvitationCode(
        app: Application,
        adminUsername: String,
        adminKey: Curve25519.KeyAgreement.PrivateKey
    ) async throws -> (code: String, token: String) {
        let adminID = try await createAdmin(
            app: app,
            username: adminUsername,
            publicKey: adminKey.publicKey.rawRepresentation.base64EncodedString()
        )
        _ = adminID
        let adminToken = try await login(app: app, username: adminUsername, clientPrivateKey: adminKey)
        let code = try await createInvitationCode(app: app, adminToken: adminToken)
        return (code, adminToken)
    }
    
    private func registerUser(
        app: Application,
        username: String,
        publicKey: String,
        invitationCode: String
    ) async throws -> String {
        let registerReq = RegisterRequest(
            username: username,
            invitationCode: invitationCode,
            publicKey: publicKey
        )
        var userID = ""
        try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
            try req.content.encode(registerReq)
        }, afterResponse: { res async throws in
            #expect(res.status == .ok)
            let user = try res.content.decode(UserResponse.self)
            #expect(user.role == "user")
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
            // 管理员生成邀请码
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (code, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin1", adminKey: adminKey)
            
            // 注册用户（绑定公钥）
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let publicKeyB64 = clientKey.publicKey.rawRepresentation.base64EncodedString()
            let userID = try await registerUser(
                app: app,
                username: "mnemonicuser",
                publicKey: publicKeyB64,
                invitationCode: code
            )
            
            // 助记词登录（挑战-响应）
            let token = try await login(
                app: app,
                username: "mnemonicuser",
                clientPrivateKey: clientKey
            )
            #expect(!token.isEmpty)
            
            // 用 token 获取用户信息
            try await app.testing().test(.GET, "api/v1/profile", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                #expect(user.id == userID)
                #expect(user.username == "mnemonicuser")
                #expect(user.role == "user")
            })
            
            // 无 token 访问被拒绝
            try await app.testing().test(.GET, "api/v1/profile", afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    @Test("Test Admin Register with Wrong Secret Rejected")
    func adminRegisterWrongSecret() async throws {
        try await withApp(configure: configure) { app in
            let key = Curve25519.KeyAgreement.PrivateKey()
            let req = AdminRegisterRequest(
                username: "hacker",
                publicKey: key.publicKey.rawRepresentation.base64EncodedString(),
                adminSecret: "wrong-secret"
            )
            try await app.testing().test(.POST, "api/v1/admin/register", beforeRequest: { r in
                try r.content.encode(req)
            }, afterResponse: { res async in
                #expect(res.status == .forbidden)
            })
        }
    }
    
    @Test("Test Admin Register Rejected When Secret Not Configured")
    func adminRegisterSecretNotConfigured() async throws {
        try await withApp(configure: configure) { app in
            // 未配置管理员引导密钥时，管理员注册用例直接抛出 503 对应错误
            let useCase = AdminRegisterUser(
                userRepository: app.userRepository,
                keyRepository: app.keyRepository,
                expectedSecret: nil
            )
            let key = Curve25519.KeyAgreement.PrivateKey()
            let input = AdminRegisterUserInput(
                username: "noconfig",
                publicKey: key.publicKey.rawRepresentation.base64EncodedString(),
                adminSecret: "anything"
            )
            
            do {
                _ = try await useCase.execute(input)
                Issue.record("应当抛出 adminSecretNotConfigured")
            } catch let error as ApplicationError {
                #expect(error == .adminSecretNotConfigured)
                #expect(error.httpStatus == 503)
            } catch {
                Issue.record("捕获到意外错误: \(error)")
            }
        }
    }
    
    @Test("Test Non-Admin Cannot Access Admin Endpoints")
    func nonAdminForbidden() async throws {
        try await withApp(configure: configure) { app in
            // 管理员生成邀请码
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (code, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin2", adminKey: adminKey)
            
            // 普通用户注册并登录
            let userKey = Curve25519.KeyAgreement.PrivateKey()
            _ = try await registerUser(
                app: app,
                username: "normaluser",
                publicKey: userKey.publicKey.rawRepresentation.base64EncodedString(),
                invitationCode: code
            )
            let userToken = try await login(app: app, username: "normaluser", clientPrivateKey: userKey)
            
            // 普通用户访问管理员接口 → 403
            try await app.testing().test(.GET, "api/v1/admin/invitations", beforeRequest: { r in
                r.headers.bearerAuthorization = BearerAuthorization(token: userToken)
            }, afterResponse: { res async in
                #expect(res.status == .forbidden)
            })
            
            // 无 token 访问管理员接口 → 401
            try await app.testing().test(.GET, "api/v1/admin/invitations", afterResponse: { res async in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    @Test("Test Admin Invitation Code Management")
    func adminInvitationManagement() async throws {
        try await withApp(configure: configure) { app in
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let adminUsername = "admin3"
            let _ = try await createAdmin(
                app: app,
                username: adminUsername,
                publicKey: adminKey.publicKey.rawRepresentation.base64EncodedString()
            )
            let adminToken = try await login(app: app, username: adminUsername, clientPrivateKey: adminKey)
            
            // 生成邀请码
            let code = try await createInvitationCode(app: app, adminToken: adminToken)
            #expect(!code.isEmpty)
            
            // 列表包含该邀请码且状态为 valid
            try await app.testing().test(.GET, "api/v1/admin/invitations", beforeRequest: { r in
                r.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let list = try res.content.decode([InvitationCodeDTO].self)
                #expect(list.contains { $0.code == code && $0.status == "valid" })
            })
            
            // 撤销邀请码
            try await app.testing().test(.DELETE, "api/v1/admin/invitations/\(code)", beforeRequest: { r in
                r.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
            
            // 撤销后列表不再包含
            try await app.testing().test(.GET, "api/v1/admin/invitations", beforeRequest: { r in
                r.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            }, afterResponse: { res async throws in
                let list = try res.content.decode([InvitationCodeDTO].self)
                #expect(!list.contains { $0.code == code })
            })
        }
    }
    
    @Test("Test Registration with Invalid Invitation Code")
    func registerWithInvalidInvitationCode() async throws {
        try await withApp(configure: configure) { app in
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let publicKeyB64 = clientKey.publicKey.rawRepresentation.base64EncodedString()
            let registerReq = RegisterRequest(
                username: "invalidinv",
                invitationCode: "NONEXISTENT123",
                publicKey: publicKeyB64
            )
            
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("Test Registration with Expired Invitation Code")
    func registerWithExpiredInvitationCode() async throws {
        try await withApp(configure: configure) { app in
            // 直接写入一条已过期的邀请码
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let adminID = try await createAdmin(
                app: app,
                username: "admin4",
                publicKey: adminKey.publicKey.rawRepresentation.base64EncodedString()
            )
            let adminIDUUID = UUID(uuidString: adminID)!
            let repository = app.invitationCodeRepository
            let expired = try await repository.create(
                code: "EXPIREDCODE",
                createdBy: adminIDUUID,
                expiresAt: Date().addingTimeInterval(-60)
            )
            #expect(expired.isExpired)
            
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            let registerReq = RegisterRequest(
                username: "expireduser",
                invitationCode: "EXPIREDCODE",
                publicKey: clientKey.publicKey.rawRepresentation.base64EncodedString()
            )
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("Test Registration with Used Invitation Code")
    func registerWithUsedInvitationCode() async throws {
        try await withApp(configure: configure) { app in
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (code, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin5", adminKey: adminKey)
            
            // 第一个用户注册成功
            let key1 = Curve25519.KeyAgreement.PrivateKey()
            _ = try await registerUser(
                app: app,
                username: "user1",
                publicKey: key1.publicKey.rawRepresentation.base64EncodedString(),
                invitationCode: code
            )
            
            // 第二个用户用同一邀请码 → 400（已使用）
            let key2 = Curve25519.KeyAgreement.PrivateKey()
            let registerReq = RegisterRequest(
                username: "user2",
                invitationCode: code,
                publicKey: key2.publicKey.rawRepresentation.base64EncodedString()
            )
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("Test Wrong Proof Rejected")
    func wrongProofRejected() async throws {
        try await withApp(configure: configure) { app in
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (code, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin6", adminKey: adminKey)
            
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            _ = try await registerUser(
                app: app,
                username: "wrongproof",
                publicKey: clientKey.publicKey.rawRepresentation.base64EncodedString(),
                invitationCode: code
            )
            
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
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (code, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin7", adminKey: adminKey)
            
            let clientKey = Curve25519.KeyAgreement.PrivateKey()
            _ = try await registerUser(
                app: app,
                username: "nickuser",
                publicKey: clientKey.publicKey.rawRepresentation.base64EncodedString(),
                invitationCode: code
            )
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
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (codeA, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin8", adminKey: adminKey)
            let (codeB, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin9", adminKey: adminKey)
            
            // 用户 A
            let keyA = Curve25519.KeyAgreement.PrivateKey()
            let pubA = keyA.publicKey.rawRepresentation.base64EncodedString()
            let userAID = try await registerUser(app: app, username: "userA", publicKey: pubA, invitationCode: codeA)
            let tokenA = try await login(app: app, username: "userA", clientPrivateKey: keyA)
            
            // 用户 B
            let keyB = Curve25519.KeyAgreement.PrivateKey()
            let pubB = keyB.publicKey.rawRepresentation.base64EncodedString()
            let userBID = try await registerUser(app: app, username: "userB", publicKey: pubB, invitationCode: codeB)
            
            // A 获取 B 的公钥
            try await app.testing().test(.GET, "api/v1/keys/\(userBID)", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: tokenA)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PublicKeyResponse.self)
                #expect(response.userID == userBID)
                #expect(response.publicKey == pubB)
            })
            
            _ = userAID
        }
    }
    
    @Test("Test Registration with Invalid Public Key")
    func registerWithInvalidPublicKey() async throws {
        try await withApp(configure: configure) { app in
            let adminKey = Curve25519.KeyAgreement.PrivateKey()
            let (code, _) = try await adminCreateInvitationCode(app: app, adminUsername: "admin10", adminKey: adminKey)
            
            let registerReq = RegisterRequest(
                username: "badkey",
                invitationCode: code,
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

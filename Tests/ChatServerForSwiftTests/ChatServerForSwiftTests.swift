@testable import ChatServerForSwift
import VaporTesting
import Testing
import Vapor

@Suite("App Tests", .serialized)
struct ChatServerForSwiftTests {
    
    // 请求体结构
    struct RegisterRequest: Content {
        let username: String
        let password: String
        let organizationCode: String
    }
    
    struct LoginRequest: Content {
        let username: String
        let password: String
    }
    
    struct ChangePasswordRequest: Content {
        let oldPassword: String
        let newPassword: String
    }
    
    struct ChangeNicknameRequest: Content {
        let nickname: String
    }
    
    struct UploadPublicKeyRequest: Content {
        let publicKey: String
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
    
    @Test("Test Health Check Route")
    func healthCheck() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "health", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "OK")
            })
        }
    }
    
    @Test("Test User Registration and Login")
    func userAuth() async throws {
        try await withApp(configure: configure) { app in
            // 1. 注册用户（使用默认组织 ORG001）
            let registerReq = RegisterRequest(
                username: "testuser",
                password: "testpass123",
                organizationCode: "ORG001"
            )
            
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                #expect(user.username == "testuser")
                #expect(user.nickname == "testuser")
                #expect(user.organizationCode == "ORG001")
            })
            
            // 2. 登录用户
            let loginReq = LoginRequest(
                username: "testuser",
                password: "testpass123"
            )
            
            try await app.testing().test(.POST, "api/v1/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                #expect(user.username == "testuser")
            })
        }
    }
    
    @Test("Test Change Password")
    func changePassword() async throws {
        try await withApp(configure: configure) { app in
            // 1. 注册用户
            let registerReq = RegisterRequest(
                username: "testuser2",
                password: "oldpassword",
                organizationCode: "ORG001"
            )
            
            var userID = ""
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                userID = user.id
            })
            
            // 2. 修改密码
            let changeReq = ChangePasswordRequest(
                oldPassword: "oldpassword",
                newPassword: "newpassword123"
            )
            
            try await app.testing().test(.POST, "api/v1/password", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: userID)
                try req.content.encode(changeReq)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
            
            // 3. 使用新密码登录
            let loginReq = LoginRequest(
                username: "testuser2",
                password: "newpassword123"
            )
            
            try await app.testing().test(.POST, "api/v1/login", beforeRequest: { req in
                try req.content.encode(loginReq)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
        }
    }
    
    @Test("Test Change Nickname")
    func changeNickname() async throws {
        try await withApp(configure: configure) { app in
            // 1. 注册用户
            let registerReq = RegisterRequest(
                username: "testuser3",
                password: "password",
                organizationCode: "ORG001"
            )
            
            var userID = ""
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                userID = user.id
            })
            
            // 2. 修改昵称
            let changeReq = ChangeNicknameRequest(nickname: "newnickname")
            
            try await app.testing().test(.POST, "api/v1/nickname", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: userID)
                try req.content.encode(changeReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let userResponse = try res.content.decode(UserResponse.self)
                #expect(userResponse.nickname == "newnickname")
            })
        }
    }
    
    @Test("Test Registration with Invalid Organization Code")
    func registerWithInvalidOrgCode() async throws {
        try await withApp(configure: configure) { app in
            // 尝试使用不存在的组织码注册
            let registerReq = RegisterRequest(
                username: "testuser4",
                password: "testpass123",
                organizationCode: "INVALID"
            )
            
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
    
    @Test("Test Upload and Get Public Key")
    func publicKeyFlow() async throws {
        try await withApp(configure: configure) { app in
            // 1. 注册用户
            let registerReq = RegisterRequest(
                username: "keyuser",
                password: "password123",
                organizationCode: "ORG001"
            )
            
            var userID = ""
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                userID = user.id
            })
            
            // 2. 上传公钥
            let publicKey = Data(count: 32).base64EncodedString()
            let keyReq = UploadPublicKeyRequest(publicKey: publicKey)
            
            try await app.testing().test(.POST, "api/v1/keys", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: userID)
                try req.content.encode(keyReq)
            }, afterResponse: { res async in
                #expect(res.status == .ok)
            })
            
            // 3. 获取公钥
            try await app.testing().test(.GET, "api/v1/keys/\(userID)", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: userID)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(PublicKeyResponse.self)
                #expect(response.publicKey == publicKey)
            })
            
            // 4. 上传无效公钥应返回 400
            let invalidReq = UploadPublicKeyRequest(publicKey: "invalid-key")
            try await app.testing().test(.POST, "api/v1/keys", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: userID)
                try req.content.encode(invalidReq)
            }, afterResponse: { res async in
                #expect(res.status == .badRequest)
            })
        }
    }
}

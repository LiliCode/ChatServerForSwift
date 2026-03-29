@testable import ChatServerForSwift
import VaporTesting
import Testing

@Suite("App Tests", .serialized)
struct ChatServerForSwiftTests {
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
            // 1. 先创建默认组织
            let organization = try await OrganizationDAO.createOrganization(
                code: "TEST001",
                name: "测试组织",
                on: app.db
            )
            
            // 2. 注册用户
            let registerReq = RegisterRequest(
                username: "testuser",
                password: "testpass123",
                organizationCode: organization.code
            )
            
            try await app.testing().test(.POST, "api/v1/register", beforeRequest: { req in
                try req.content.encode(registerReq)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let user = try res.content.decode(UserResponse.self)
                #expect(user.username == "testuser")
                #expect(user.nickname == "testuser")
                #expect(user.organizationCode == "TEST001")
            })
            
            // 3. 登录用户
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
            // 1. 创建组织和用户
            let organization = try await OrganizationDAO.createOrganization(
                code: "TEST002",
                name: "测试组织2",
                on: app.db
            )
            
            let user = try await UserDAO.createUser(
                username: "testuser2",
                passwordHash: PasswordHasher.hash("oldpassword"),
                nickname: "testuser2",
                organizationCode: organization.code,
                on: app.db
            )
            
            // 2. 修改密码
            let changeReq = ChangePasswordRequest(
                oldPassword: "oldpassword",
                newPassword: "newpassword123"
            )
            
            try await app.testing().test(.POST, "api/v1/password", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: user.id!.uuidString)
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
            // 1. 创建组织和用户
            let organization = try await OrganizationDAO.createOrganization(
                code: "TEST003",
                name: "测试组织3",
                on: app.db
            )
            
            let user = try await UserDAO.createUser(
                username: "testuser3",
                passwordHash: PasswordHasher.hash("password"),
                nickname: "oldnickname",
                organizationCode: organization.code,
                on: app.db
            )
            
            // 2. 修改昵称
            let changeReq = ChangeNicknameRequest(nickname: "newnickname")
            
            try await app.testing().test(.POST, "api/v1/nickname", beforeRequest: { req in
                req.headers.add(name: "X-User-ID", value: user.id!.uuidString)
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
}

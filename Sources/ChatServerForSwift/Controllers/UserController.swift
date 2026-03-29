import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "v1")
        
        // 公开接口（不需要认证）
        api.post("register", use: register)
        api.post("login", use: login)
        
        // 需要认证的接口
        let protected = api.grouped(AuthMiddleware())
        protected.get("profile", use: getProfile)
        protected.post("password", use: changePassword)
        protected.post("nickname", use: changeNickname)
    }
    
    // MARK: - 注册
    
    func register(req: Request) async throws -> UserResponse {
        let registerReq = try req.content.decode(RegisterRequest.self)
        
        // 验证参数
        guard registerReq.username.count >= 3 else {
            throw Abort(.badRequest, reason: "用户名至少需要3个字符")
        }
        guard registerReq.password.count >= 6 else {
            throw Abort(.badRequest, reason: "密码至少需要6个字符")
        }
        guard !registerReq.organizationCode.isEmpty else {
            throw Abort(.badRequest, reason: "组织码不能为空")
        }
        
        // 验证组织码是否存在
        guard try await OrganizationDAO.existsByCode(registerReq.organizationCode, on: req.db) else {
            throw Abort(.badRequest, reason: "组织码不存在")
        }
        
        // 检查用户名是否已存在
        if try await UserDAO.existsByUsername(registerReq.username, on: req.db) {
            throw Abort(.conflict, reason: "用户名已存在")
        }
        
        // 创建用户
        let passwordHash = PasswordHasher.hash(registerReq.password)
        let user = try await UserDAO.createUser(
            username: registerReq.username,
            passwordHash: passwordHash,
            nickname: registerReq.username,
            organizationCode: registerReq.organizationCode,
            on: req.db
        )
        
        return user.toResponse()
    }
    
    // MARK: - 登录
    
    func login(req: Request) async throws -> UserResponse {
        let loginReq = try req.content.decode(LoginRequest.self)
        
        // 查找用户
        guard let user = try await UserDAO.findByUsername(loginReq.username, on: req.db) else {
            throw Abort(.unauthorized, reason: "用户名或密码错误")
        }
        
        // 验证密码
        guard PasswordHasher.verify(loginReq.password, against: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "用户名或密码错误")
        }
        
        // 将用户ID存入session（使用header传递）
        req.headers.add(name: "X-User-ID", value: user.id!.uuidString)
        
        return user.toResponse()
    }
    
    // MARK: - 获取用户信息
    
    func getProfile(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        return user.toResponse()
    }
    
    // MARK: - 修改密码
    
    func changePassword(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let changeReq = try req.content.decode(ChangePasswordRequest.self)
        
        // 验证旧密码
        guard PasswordHasher.verify(changeReq.oldPassword, against: user.passwordHash) else {
            throw Abort(.badRequest, reason: "旧密码错误")
        }
        
        // 验证新密码长度
        guard changeReq.newPassword.count >= 6 else {
            throw Abort(.badRequest, reason: "新密码至少需要6个字符")
        }
        
        // 更新密码
        let newPasswordHash = PasswordHasher.hash(changeReq.newPassword)
        try await UserDAO.updatePassword(user: user, newPasswordHash: newPasswordHash, on: req.db)
        
        return Response(status: .ok, body: .init(string: "密码修改成功"))
    }
    
    // MARK: - 修改昵称
    
    func changeNickname(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        let changeReq = try req.content.decode(ChangeNicknameRequest.self)
        
        // 验证昵称长度
        guard changeReq.nickname.count >= 1 && changeReq.nickname.count <= 20 else {
            throw Abort(.badRequest, reason: "昵称长度需要在1-20个字符之间")
        }
        
        // 更新昵称
        try await UserDAO.updateNickname(user: user, newNickname: changeReq.nickname, on: req.db)
        
        return user.toResponse()
    }
}

// MARK: - DTOs

/// 用户注册请求
struct RegisterRequest: Content {
    let username: String
    let password: String
    let organizationCode: String
}

/// 用户登录请求
struct LoginRequest: Content {
    let username: String
    let password: String
}

/// 修改密码请求
struct ChangePasswordRequest: Content {
    let oldPassword: String
    let newPassword: String
}

/// 修改昵称请求
struct ChangeNicknameRequest: Content {
    let nickname: String
}

/// 用户信息响应
struct UserResponse: Content {
    let id: String
    let username: String
    let nickname: String
    let organizationCode: String
    let createdAt: Date?
}

extension User {
    func toResponse() -> UserResponse {
        UserResponse(
            id: id!.uuidString,
            username: username,
            nickname: nickname,
            organizationCode: organizationCode,
            createdAt: createdAt
        )
    }
}

// MARK: - 密码工具

import CryptoKit

enum PasswordHasher {
    /// 哈希密码
    static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 验证密码
    static func verify(_ password: String, against hash: String) -> Bool {
        Self.hash(password) == hash
    }
}

// MARK: - 认证中间件

struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 从请求头中获取用户ID
        guard let userIDString = request.headers.first(name: "X-User-ID"),
              let userID = UUID(uuidString: userIDString) else {
            throw Abort(.unauthorized, reason: "未登录")
        }
        
        // 查询用户
        guard let user = try await UserDAO.findByID(userID, on: request.db) else {
            throw Abort(.unauthorized, reason: "用户不存在")
        }
        
        // 将用户存入auth
        request.auth.login(user)
        
        return try await next.respond(to: request)
    }
}

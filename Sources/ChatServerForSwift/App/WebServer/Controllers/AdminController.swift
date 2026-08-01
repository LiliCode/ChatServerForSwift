import Vapor

/// 后台管理控制器（邀请码管理）
struct AdminController: RouteCollection {
    private let adminRegisterUser: AdminRegisterUser
    private let createInvitationCode: CreateInvitationCode
    private let listInvitationCodes: ListInvitationCodes
    private let revokeInvitationCode: RevokeInvitationCode
    private let authMiddleware: AuthMiddleware
    private let adminMiddleware: AdminMiddleware
    
    init(
        adminRegisterUser: AdminRegisterUser,
        createInvitationCode: CreateInvitationCode,
        listInvitationCodes: ListInvitationCodes,
        revokeInvitationCode: RevokeInvitationCode,
        authMiddleware: AuthMiddleware,
        adminMiddleware: AdminMiddleware
    ) {
        self.adminRegisterUser = adminRegisterUser
        self.createInvitationCode = createInvitationCode
        self.listInvitationCodes = listInvitationCodes
        self.revokeInvitationCode = revokeInvitationCode
        self.authMiddleware = authMiddleware
        self.adminMiddleware = adminMiddleware
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "v1", "admin")
        
        // 管理员注册（凭管理员密钥引导，无需登录）
        api.post("register", use: adminRegister)
        
        // 需要管理员角色的接口（先认证，再校验角色）
        let protected = api.grouped(authMiddleware, adminMiddleware)
        protected.post("invitations", use: createInvitation)
        protected.get("invitations", use: listInvitations)
        protected.delete("invitations", ":code", use: revokeInvitation)
    }
    
    // MARK: - 管理员注册
    
    func adminRegister(req: Request) async throws -> UserResponseDTO {
        let input = try req.content.decode(AdminRegisterRequest.self)
        let useCaseInput = AdminRegisterUserInput(
            username: input.username,
            publicKey: input.publicKey,
            adminSecret: input.adminSecret
        )
        let userDTO = try await adminRegisterUser.execute(useCaseInput)
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 生成邀请码
    
    func createInvitation(req: Request) async throws -> InvitationCodeDTO {
        let userID = try req.auth.require(UserID.self).value
        let input = try req.content.decode(CreateInvitationRequest.self)
        
        let expiresAt = input.expiresAt ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        let useCaseInput = CreateInvitationCodeInput(
            createdBy: userID,
            expiresAt: expiresAt
        )
        
        return try await createInvitationCode.execute(useCaseInput)
    }
    
    // MARK: - 邀请码列表
    
    func listInvitations(req: Request) async throws -> [InvitationCodeDTO] {
        try await listInvitationCodes.execute()
    }
    
    // MARK: - 撤销邀请码
    
    func revokeInvitation(req: Request) async throws -> HTTPStatus {
        guard let code = req.parameters.get("code") else {
            throw Abort(.badRequest, reason: "缺少邀请码")
        }
        try await revokeInvitationCode.execute(RevokeInvitationCodeInput(code: code))
        return .ok
    }
}

// MARK: - Request DTOs

public struct AdminRegisterRequest: Content {
    let username: String
    let publicKey: String
    let adminSecret: String
}

public struct CreateInvitationRequest: Content {
    let expiresAt: Date?
}

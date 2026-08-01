import Vapor

/// 管理员认证中间件（校验用户角色为 admin）
struct AdminMiddleware: AsyncMiddleware {
    private let userRepository: any UserRepository
    
    init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }
    
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 需要先经过 AuthMiddleware，从中取出用户ID
        guard let userID = request.auth.get(UserID.self)?.value else {
            throw Abort(.unauthorized, reason: "未登录")
        }
        
        guard let user = try await userRepository.findByID(userID) else {
            throw Abort(.unauthorized, reason: "用户不存在")
        }
        
        guard user.role.isAdmin else {
            throw Abort(.forbidden, reason: "需要管理员权限")
        }
        
        return try await next.respond(to: request)
    }
}

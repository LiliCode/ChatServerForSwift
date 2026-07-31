import Vapor

/// 认证中间件（不透明会话令牌验证）
struct AuthMiddleware: AsyncMiddleware {
    private let tokenRepository: any TokenRepository
    
    init(tokenRepository: any TokenRepository) {
        self.tokenRepository = tokenRepository
    }
    
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 从 Authorization: Bearer <token> 提取令牌
        guard let bearer = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "未登录")
        }
        
        // 校验令牌并解析用户
        guard let userID = try await tokenRepository.findUserID(for: bearer.token) else {
            throw Abort(.unauthorized, reason: "登录已过期或无效")
        }
        
        // 将用户ID存入 auth
        request.auth.login(UserID(value: userID))
        
        return try await next.respond(to: request)
    }
}

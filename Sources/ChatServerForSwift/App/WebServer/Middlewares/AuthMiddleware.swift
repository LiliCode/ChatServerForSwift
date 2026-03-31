import Vapor

/// 认证中间件
struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        // 从请求头中获取用户ID
        guard let userIDString = request.headers.first(name: "X-User-ID"),
              let userID = UUID(uuidString: userIDString) else {
            throw Abort(.unauthorized, reason: "未登录")
        }
        
        // 将用户ID存入 auth
        request.auth.login(UserID(value: userID))
        
        return try await next.respond(to: request)
    }
}

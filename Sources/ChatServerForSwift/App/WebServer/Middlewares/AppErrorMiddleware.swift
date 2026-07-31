import Vapor

/// 将领域层/应用层错误映射为 HTTP 状态码
struct AppErrorMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do {
            return try await next.respond(to: request)
        } catch let error as DomainError {
            throw Abort(HTTPResponseStatus(statusCode: Int(error.httpStatus)), reason: error.message)
        } catch let error as ApplicationError {
            throw Abort(HTTPResponseStatus(statusCode: Int(error.httpStatus)), reason: error.message)
        } catch {
            throw error
        }
    }
}

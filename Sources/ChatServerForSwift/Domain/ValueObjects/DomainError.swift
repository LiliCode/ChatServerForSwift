import Foundation

/// 领域层错误
public enum DomainError: Error, Sendable {
    case validationError(String)
    case notFound(String)
    case alreadyExists(String)
    
    public var message: String {
        switch self {
        case .validationError(let msg):
            return msg
        case .notFound(let msg):
            return msg
        case .alreadyExists(let msg):
            return msg
        }
    }
    
    /// HTTP 状态码（不依赖 Vapor，由基础设施层转换）
    public var httpStatus: UInt {
        switch self {
        case .validationError:
            return 400
        case .notFound:
            return 404
        case .alreadyExists:
            return 409
        }
    }
}

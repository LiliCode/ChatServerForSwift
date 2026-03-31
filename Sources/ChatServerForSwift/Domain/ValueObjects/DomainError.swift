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
}

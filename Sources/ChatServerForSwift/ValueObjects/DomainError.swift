import Foundation
import Vapor

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

// MARK: - AbortError 协议实现

extension DomainError: AbortError {
    public var status: HTTPResponseStatus {
        switch self {
        case .validationError:
            return .badRequest
        case .notFound:
            return .notFound
        case .alreadyExists:
            return .conflict
        }
    }
    
    public var reason: String {
        return message
    }
}

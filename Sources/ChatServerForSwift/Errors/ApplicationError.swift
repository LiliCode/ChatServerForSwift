import Foundation
import Vapor

/// 应用层错误
public enum ApplicationError: Error, Sendable {
    case validationError(String)
    case userNotFound
    case organizationNotFound
    case usernameAlreadyExists
    case invalidCredentials
    case invalidOldPassword
    case userOffline
    
    public var message: String {
        switch self {
        case .validationError(let msg):
            return msg
        case .userNotFound:
            return "用户不存在"
        case .organizationNotFound:
            return "组织不存在"
        case .usernameAlreadyExists:
            return "用户名已存在"
        case .invalidCredentials:
            return "用户名或密码错误"
        case .invalidOldPassword:
            return "旧密码错误"
        case .userOffline:
            return "用户离线"
        }
    }
}

// MARK: - AbortError 协议实现

extension ApplicationError: AbortError {
    public var status: HTTPResponseStatus {
        switch self {
        case .validationError:
            return .badRequest
        case .userNotFound:
            return .notFound
        case .organizationNotFound:
            return .badRequest
        case .usernameAlreadyExists:
            return .conflict
        case .invalidCredentials:
            return .unauthorized
        case .invalidOldPassword:
            return .badRequest
        case .userOffline:
            return .badRequest
        }
    }
    
    public var reason: String {
        return message
    }
}

import Foundation

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
    
    /// HTTP 状态码（不依赖 Vapor，由基础设施层转换）
    public var httpStatus: UInt {
        switch self {
        case .validationError:
            return 400
        case .userNotFound:
            return 404
        case .organizationNotFound:
            return 400
        case .usernameAlreadyExists:
            return 409
        case .invalidCredentials:
            return 401
        case .invalidOldPassword:
            return 400
        case .userOffline:
            return 409
        }
    }
}

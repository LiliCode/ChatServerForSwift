import Foundation

/// 应用层错误
public enum ApplicationError: Error, Sendable {
    case validationError(String)
    case userNotFound
    case organizationNotFound
    case usernameAlreadyExists
    case userOffline
    case publicKeyNotSet
    case invalidChallenge
    case invalidKeyProof
    
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
        case .userOffline:
            return "用户离线"
        case .publicKeyNotSet:
            return "账号尚未绑定公钥"
        case .invalidChallenge:
            return "登录挑战无效或已过期"
        case .invalidKeyProof:
            return "密钥校验失败"
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
        case .userOffline:
            return 409
        case .publicKeyNotSet:
            return 400
        case .invalidChallenge:
            return 401
        case .invalidKeyProof:
            return 401
        }
    }
}

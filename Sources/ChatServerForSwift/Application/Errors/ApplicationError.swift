import Foundation

/// 应用层错误
public enum ApplicationError: Error, Sendable, Equatable {
    case validationError(String)
    case userNotFound
    case usernameAlreadyExists
    case userOffline
    case publicKeyNotSet
    case invalidChallenge
    case invalidKeyProof
    case invitationCodeNotFound
    case invitationCodeExpired
    case invitationCodeUsed
    case adminSecretInvalid
    case adminSecretNotConfigured
    case notAdmin
    
    public var message: String {
        switch self {
        case .validationError(let msg):
            return msg
        case .userNotFound:
            return "用户不存在"
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
        case .invitationCodeNotFound:
            return "邀请码不存在或无效"
        case .invitationCodeExpired:
            return "邀请码已过期，请重新填写有效的邀请码"
        case .invitationCodeUsed:
            return "邀请码已被使用"
        case .adminSecretInvalid:
            return "管理员密钥无效"
        case .adminSecretNotConfigured:
            return "管理员引导密钥未配置，请在部署时设置环境变量 ADMIN_SETUP_SECRET"
        case .notAdmin:
            return "需要管理员权限"
        }
    }
    
    /// HTTP 状态码（不依赖 Vapor，由基础设施层转换）
    public var httpStatus: UInt {
        switch self {
        case .validationError:
            return 400
        case .userNotFound:
            return 404
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
        case .invitationCodeNotFound:
            return 400
        case .invitationCodeExpired:
            return 400
        case .invitationCodeUsed:
            return 400
        case .adminSecretInvalid:
            return 403
        case .adminSecretNotConfigured:
            return 503
        case .notAdmin:
            return 403
        }
    }
}

import Foundation
import Vapor

// MARK: - 管理员注册输入

/// 管理员注册输入（通过管理员密钥引导）
public struct AdminRegisterUserInput: Sendable {
    public let username: String
    public let publicKey: String
    public let adminSecret: String
    
    public init(username: String, publicKey: String, adminSecret: String) {
        self.username = username
        self.publicKey = publicKey
        self.adminSecret = adminSecret
    }
}

// MARK: - 邀请码输入

/// 生成邀请码输入
public struct CreateInvitationCodeInput: Sendable {
    public let createdBy: UUID
    public let expiresAt: Date
    
    public init(createdBy: UUID, expiresAt: Date) {
        self.createdBy = createdBy
        self.expiresAt = expiresAt
    }
}

/// 撤销邀请码输入
public struct RevokeInvitationCodeInput: Sendable {
    public let code: String
    
    public init(code: String) {
        self.code = code
    }
}

// MARK: - 邀请码输出

/// 邀请码响应 DTO
public struct InvitationCodeDTO: Content, Sendable {
    public let code: String
    public let createdAt: Date?
    public let expiresAt: Date
    public let status: String
    
    public init(code: String, createdAt: Date?, expiresAt: Date, status: String) {
        self.code = code
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.status = status
    }
    
    public init(invitation: InvitationCode) {
        self.code = invitation.code
        self.createdAt = invitation.createdAt
        self.expiresAt = invitation.expiresAt
        if invitation.isUsed {
            self.status = "used"
        } else if invitation.isExpired {
            self.status = "expired"
        } else {
            self.status = "valid"
        }
    }
}

import Foundation

/// 邀请码领域实体（单次使用，带过期时间）
public struct InvitationCode: Sendable, Identifiable {
    public let id: UUID
    public let code: String
    public let createdBy: UUID
    public let createdAt: Date
    public let expiresAt: Date
    public let usedBy: UUID?
    public let usedAt: Date?
    
    public init(
        id: UUID,
        code: String,
        createdBy: UUID,
        createdAt: Date,
        expiresAt: Date,
        usedBy: UUID? = nil,
        usedAt: Date? = nil
    ) {
        self.id = id
        self.code = code
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.usedBy = usedBy
        self.usedAt = usedAt
    }
    
    /// 是否已过期
    public var isExpired: Bool {
        Date() > expiresAt
    }
    
    /// 是否已被使用（单次使用）
    public var isUsed: Bool {
        usedBy != nil || usedAt != nil
    }
    
    /// 是否仍然有效（未过期且未使用）
    public var isValid: Bool {
        !isExpired && !isUsed
    }
}

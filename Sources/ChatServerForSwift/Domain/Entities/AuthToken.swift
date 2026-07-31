import Foundation

/// 会话令牌领域实体
public struct AuthToken: Sendable, Identifiable {
    public let id: UUID
    public let userID: UUID
    public let token: String
    public let createdAt: Date
    public let expiresAt: Date?
    
    public init(
        id: UUID,
        userID: UUID,
        token: String,
        createdAt: Date,
        expiresAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.token = token
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    public var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
}

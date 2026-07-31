import Foundation

/// 用户公钥领域实体（E2EE 密钥恢复用）
public struct UserKey: Sendable, Identifiable {
    public let userID: UUID
    public let publicKey: String
    public let createdAt: Date
    
    public var id: UUID { userID }
    
    public init(
        userID: UUID,
        publicKey: String,
        createdAt: Date
    ) {
        self.userID = userID
        self.publicKey = publicKey
        self.createdAt = createdAt
    }
}

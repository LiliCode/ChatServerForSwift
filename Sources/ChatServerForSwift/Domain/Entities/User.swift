import Foundation

/// 用户领域实体
public struct User: Sendable, Identifiable {
    public let id: UUID
    public let username: String
    public let nickname: String
    public let organizationCode: String
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        id: UUID,
        username: String,
        nickname: String,
        organizationCode: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.organizationCode = organizationCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

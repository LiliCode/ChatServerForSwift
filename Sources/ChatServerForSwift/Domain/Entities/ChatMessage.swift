import Foundation

/// 聊天消息领域实体
public struct ChatMessage: Sendable, Identifiable {
    public let id: String
    public let fromUserID: UUID
    public let toUserID: UUID
    public let content: Data
    public let timestamp: Date
    
    public init(
        id: String,
        fromUserID: UUID,
        toUserID: UUID,
        content: Data,
        timestamp: Date
    ) {
        self.id = id
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.content = content
        self.timestamp = timestamp
    }
}

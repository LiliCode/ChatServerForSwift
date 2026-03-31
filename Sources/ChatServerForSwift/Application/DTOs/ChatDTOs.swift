import Foundation

// MARK: - Input DTOs

/// 发送消息输入
public struct SendMessageInput: Sendable {
    public let fromUserID: UUID
    public let toUserID: UUID
    public let content: Data
    public let messageID: String
    
    public init(
        fromUserID: UUID,
        toUserID: UUID,
        content: Data,
        messageID: String
    ) {
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.content = content
        self.messageID = messageID
    }
}

/// 消息回执输入
public struct MessageReceiptInput: Sendable {
    public let userID: UUID
    public let messageID: String
    
    public init(userID: UUID, messageID: String) {
        self.userID = userID
        self.messageID = messageID
    }
}

// MARK: - Output DTOs

/// 消息 DTO
public struct MessageDTO: Sendable {
    public let id: String
    public let fromUserID: String
    public let toUserID: String
    public let content: Data
    public let timestamp: Int64
    
    public init(
        id: String,
        fromUserID: String,
        toUserID: String,
        content: Data,
        timestamp: Int64
    ) {
        self.id = id
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.content = content
        self.timestamp = timestamp
    }
}

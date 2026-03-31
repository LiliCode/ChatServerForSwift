import Vapor
import Foundation

/// WebSocket 连接管理器实现
public actor WebSocketConnectionManager: ChatConnectionManager {
    public static let shared = WebSocketConnectionManager()
    
    private var connections: [UUID: WebSocket] = [:]
    private var messageCache: (any MessageCache)?
    
    private init() {}
    
    public func configure(messageCache: any MessageCache) {
        self.messageCache = messageCache
    }
    
    // MARK: - 连接管理
    
    public func addConnection(userID: UUID, socket: WebSocket) {
        connections[userID] = socket
    }
    
    public func removeConnection(userID: UUID) {
        connections.removeValue(forKey: userID)
    }
    
    public func isUserOnline(_ userID: UUID) async -> Bool {
        connections[userID] != nil
    }
    
    // MARK: - 消息发送
    
    public func sendMessage(to userID: UUID, message: ChatMessage) async throws {
        guard let socket = connections[userID] else {
            throw ApplicationError.userOffline
        }
        
        // 构建 PushMessage
        var pushMessage = PushMessage()
        pushMessage.from = uuidToInt64(message.fromUserID)
        pushMessage.to = uuidToInt64(message.toUserID)
        pushMessage.timestamp = Int64(message.timestamp.timeIntervalSince1970 * 1000)
        pushMessage.hash = message.id
        pushMessage.payload = message.content
        
        let messageData = try pushMessage.serializedData()
        try await socket.send(raw: messageData, opcode: .binary)
    }
    
    /// 推送离线消息
    public func pushOfflineMessages(to userID: UUID) async throws {
        guard let messageCache = messageCache else { return }
        
        let messages = try await messageCache.fetchAndClearOfflineMessages(for: userID)
        
        for message in messages {
            try await sendMessage(to: userID, message: message)
        }
    }
}

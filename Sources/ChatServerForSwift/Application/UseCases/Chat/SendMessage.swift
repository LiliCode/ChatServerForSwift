import Foundation

/// 发送消息用例
public struct SendMessage: Sendable {
    private let userRepository: any UserRepository
    private let connectionManager: any ChatConnectionManager
    private let messageCache: any MessageCache
    
    public init(
        userRepository: any UserRepository,
        connectionManager: any ChatConnectionManager,
        messageCache: any MessageCache
    ) {
        self.userRepository = userRepository
        self.connectionManager = connectionManager
        self.messageCache = messageCache
    }
    
    public func execute(_ input: SendMessageInput) async throws {
        // 1. 验证接收者是否存在
        guard let _ = try await userRepository.findByID(input.toUserID) else {
            throw ApplicationError.userNotFound
        }
        
        // 2. 构建 PushMessage (protobuf)
        var pushMessage = PushMessage()
        pushMessage.from = uuidToInt64(input.fromUserID)
        pushMessage.to = uuidToInt64(input.toUserID)
        pushMessage.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        pushMessage.hash = input.messageID
        pushMessage.payload = input.content
        
        let messageData = try pushMessage.serializedData()
        
        // 3. 始终缓存到 Redis，等回执到达才删除，最大限度防止丢消息
        try await messageCache.cacheOfflineMessage(for: input.toUserID, messageData: messageData)
        
        // 4. 接收者在线则立即推送
        if await connectionManager.isUserOnline(input.toUserID) {
            try await connectionManager.sendMessageData(to: input.toUserID, data: messageData)
        }
    }
}

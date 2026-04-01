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
        
        // 3. 检查接收者是否在线
        if await connectionManager.isUserOnline(input.toUserID) {
            // 在线，直接发送二进制数据
            try await connectionManager.sendMessageData(to: input.toUserID, data: messageData)
        } else {
            // 离线，直接缓存二进制数据
            try await messageCache.cacheOfflineMessage(for: input.toUserID, messageData: messageData)
        }
    }
}

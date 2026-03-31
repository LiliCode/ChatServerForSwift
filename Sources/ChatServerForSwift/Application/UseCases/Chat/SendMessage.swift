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
        
        // 2. 创建消息实体
        let message = ChatMessage(
            id: input.messageID,
            fromUserID: input.fromUserID,
            toUserID: input.toUserID,
            content: input.content,
            timestamp: Date()
        )
        
        // 3. 检查接收者是否在线
		if await connectionManager.isUserOnline(input.toUserID) {
            // 在线，直接发送
            try await connectionManager.sendMessage(to: input.toUserID, message: message)
        } else {
            // 离线，缓存消息
            try await messageCache.cacheOfflineMessage(for: input.toUserID, message: message)
        }
    }
}

import Foundation

/// 处理消息回执用例
public struct ProcessReceipt: Sendable {
	private let messageCache: any MessageCache
    
	public init(messageCache: any MessageCache) {
        self.messageCache = messageCache
    }
    
    public func execute(_ input: MessageReceiptInput) async throws {
        // 删除已确认的消息
        try await messageCache.removeConfirmedMessage(
            userID: input.userID,
            messageID: input.messageID
        )
    }
}

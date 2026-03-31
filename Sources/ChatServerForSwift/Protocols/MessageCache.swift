import Foundation

/// 消息缓存接口
public protocol MessageCache: Sendable {
    /// 缓存离线消息
    func cacheOfflineMessage(for userID: UUID, message: ChatMessage) async throws
    
    /// 获取并清空离线消息
    func fetchAndClearOfflineMessages(for userID: UUID) async throws -> [ChatMessage]
    
    /// 删除已确认的消息
    func removeConfirmedMessage(userID: UUID, messageID: String) async throws
}

import Foundation

/// 消息缓存接口
public protocol MessageCache: Sendable {
    /// 缓存离线消息 - 直接存储 protobuf 二进制数据
    func cacheOfflineMessage(for userID: UUID, messageData: Data) async throws
    
    /// 获取并清空离线消息 - 返回 protobuf 二进制数据列表
    func fetchAndClearOfflineMessages(for userID: UUID) async throws -> [Data]
    
    /// 删除已确认的消息
    func removeConfirmedMessage(userID: UUID, messageID: String) async throws
}

import Foundation

/// 聊天连接管理接口
public protocol ChatConnectionManager: Sendable {
    /// 用户是否在线
    func isUserOnline(_ userID: UUID) async -> Bool
    
    /// 发送消息给用户
    func sendMessage(to userID: UUID, message: ChatMessage) async throws
}

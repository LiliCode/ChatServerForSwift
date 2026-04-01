import Foundation

/// 聊天连接管理接口
public protocol ChatConnectionManager: Sendable {
    /// 用户是否在线
    func isUserOnline(_ userID: UUID) async -> Bool
    
    /// 发送消息给用户（使用 protobuf 二进制数据）
    func sendMessageData(to userID: UUID, data: Data) async throws
    
    /// 发送消息给用户（使用 ChatMessage 实体）
    func sendMessage(to userID: UUID, message: ChatMessage) async throws
}

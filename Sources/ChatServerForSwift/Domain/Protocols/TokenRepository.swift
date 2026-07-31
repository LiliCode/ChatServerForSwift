import Foundation

/// 会话令牌仓库接口
public protocol TokenRepository: Sendable {
    /// 为用户创建会话令牌
    func create(for userID: UUID) async throws -> AuthToken
    
    /// 根据令牌查找对应用户（过期令牌返回 nil）
    func findUserID(for token: String) async throws -> UUID?
    
    /// 删除令牌（登出）
    func delete(for token: String) async throws
}

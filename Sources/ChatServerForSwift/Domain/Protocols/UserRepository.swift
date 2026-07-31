import Foundation

/// 用户仓库接口
public protocol UserRepository: Sendable {
    /// 根据用户名查找用户
    func findByUsername(_ username: String) async throws -> User?
    
    /// 根据ID查找用户
    func findByID(_ id: UUID) async throws -> User?
    
    /// 检查用户名是否已存在
    func existsByUsername(_ username: String) async throws -> Bool
    
    /// 创建用户
    func create(_ user: User) async throws -> User
    
    /// 更新昵称
    func updateNickname(userID: UUID, newNickname: String) async throws
}

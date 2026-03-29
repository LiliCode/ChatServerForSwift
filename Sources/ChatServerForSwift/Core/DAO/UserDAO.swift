import Vapor
import Fluent

/// 用户数据访问对象
enum UserDAO {
    /// 根据用户名查找用户
    static func findByUsername(_ username: String, on db: any Database) async throws -> User? {
        try await User.query(on: db)
            .filter(\.$username == username)
            .first()
    }
    
    /// 根据ID查找用户
    static func findByID(_ id: UUID, on db: any Database) async throws -> User? {
        try await User.find(id, on: db)
    }
    
    /// 检查用户名是否已存在
    static func existsByUsername(_ username: String, on db: any Database) async throws -> Bool {
        try await User.query(on: db)
            .filter(\.$username == username)
            .first() != nil
    }
    
    /// 创建用户
    static func createUser(
        username: String,
        passwordHash: String,
        nickname: String,
        organizationCode: String,
        on db: any Database
    ) async throws -> User {
        let user = User(
            username: username,
            passwordHash: passwordHash,
            nickname: nickname,
            organizationCode: organizationCode
        )
        try await user.save(on: db)
        return user
    }
    
    /// 更新密码
    static func updatePassword(user: User, newPasswordHash: String, on db: any Database) async throws {
        user.passwordHash = newPasswordHash
        try await user.save(on: db)
    }
    
    /// 更新昵称
    static func updateNickname(user: User, newNickname: String, on db: any Database) async throws {
        user.nickname = newNickname
        try await user.save(on: db)
    }
}

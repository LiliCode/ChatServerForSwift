import Vapor
import Fluent

/// Fluent 用户仓库实现
public struct FluentUserRepository: UserRepository {
    private let db: any Database
    
    public init(db: any Database) {
        self.db = db
    }
    
    public func findByUsername(_ username: String) async throws -> User? {
        guard let model = try await UserFluentModel.query(on: db)
            .filter(\.$username == username)
            .first() else {
            return nil
        }
        return model.toDomain()
    }
    
    public func findByID(_ id: UUID) async throws -> User? {
        guard let model = try await UserFluentModel.find(id, on: db) else {
            return nil
        }
        return model.toDomain()
    }
    
    public func existsByUsername(_ username: String) async throws -> Bool {
        try await UserFluentModel.query(on: db)
            .filter(\.$username == username)
            .first() != nil
    }
    
    public func create(_ user: User) async throws -> User {
        let model = user.toFluentModel()
        try await model.save(on: db)
        return model.toDomain()
    }
    
    public func updateNickname(userID: UUID, newNickname: String) async throws {
        guard let model = try await UserFluentModel.find(userID, on: db) else {
            throw DomainError.notFound("用户不存在")
        }
        model.nickname = newNickname
        try await model.save(on: db)
    }
}

import Vapor
import Fluent

/// Fluent 用户公钥仓库实现
public struct FluentKeyRepository: KeyRepository {
    private let db: any Database
    
    public init(db: any Database) {
        self.db = db
    }
    
    public func findPublicKey(for userID: UUID) async throws -> String? {
        guard let model = try await UserFluentModel.find(userID, on: db) else {
            return nil
        }
        return model.publicKey
    }
    
    public func upsertPublicKey(_ publicKey: String, for userID: UUID) async throws {
        guard let model = try await UserFluentModel.find(userID, on: db) else {
            throw DomainError.notFound("用户不存在")
        }
        model.publicKey = publicKey
        try await model.save(on: db)
    }
}

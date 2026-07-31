import Vapor
import Fluent

/// Fluent 会话令牌仓库实现
public struct FluentTokenRepository: TokenRepository {
    private let db: any Database
    
    public init(db: any Database) {
        self.db = db
    }
    
    public func create(for userID: UUID) async throws -> AuthToken {
        let token = AuthToken(
            id: UUID(),
            userID: userID,
            token: UUID().uuidString,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60)
        )
        let model = TokenFluentModel(
            id: token.id,
            userID: token.userID,
            token: token.token,
            expiresAt: token.expiresAt
        )
        try await model.save(on: db)
        return token
    }
    
    public func findUserID(for token: String) async throws -> UUID? {
        guard let model = try await TokenFluentModel.query(on: db)
            .filter(\.$token == token)
            .first() else {
            return nil
        }
        let domain = model.toDomain()
        if domain.isExpired {
            try? await model.delete(on: db)
            return nil
        }
        return domain.userID
    }
    
    public func delete(for token: String) async throws {
        try await TokenFluentModel.query(on: db)
            .filter(\.$token == token)
            .delete()
    }
}

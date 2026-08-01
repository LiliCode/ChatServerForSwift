import Vapor
import Fluent

/// Fluent 邀请码仓库实现
public struct FluentInvitationCodeRepository: InvitationCodeRepository {
    private let db: any Database
    
    public init(db: any Database) {
        self.db = db
    }
    
    public func findByCode(_ code: String) async throws -> InvitationCode? {
        guard let model = try await InvitationCodeFluentModel.query(on: db)
            .filter(\.$code == code)
            .first() else {
            return nil
        }
        return model.toDomain()
    }
    
    public func create(code: String, createdBy: UUID, expiresAt: Date) async throws -> InvitationCode {
        let model = InvitationCodeFluentModel(
            code: code,
            createdBy: createdBy,
            expiresAt: expiresAt
        )
        try await model.save(on: db)
        return model.toDomain()
    }
    
    public func markUsed(code: String, usedBy: UUID) async throws {
        guard let model = try await InvitationCodeFluentModel.query(on: db)
            .filter(\.$code == code)
            .first() else {
            throw DomainError.notFound("邀请码不存在")
        }
        model.usedBy = usedBy
        model.usedAt = Date()
        try await model.save(on: db)
    }
    
    public func list() async throws -> [InvitationCode] {
        try await InvitationCodeFluentModel.query(on: db)
            .all()
            .map { $0.toDomain() }
    }
    
    public func revoke(code: String) async throws {
        try await InvitationCodeFluentModel.query(on: db)
            .filter(\.$code == code)
            .delete()
    }
}

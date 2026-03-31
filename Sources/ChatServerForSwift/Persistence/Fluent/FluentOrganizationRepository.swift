import Vapor
import Fluent

/// Fluent 组织仓库实现
public struct FluentOrganizationRepository: OrganizationRepository {
    private let db: any Database
    
    public init(db: any Database) {
        self.db = db
    }
    
    public func findByCode(_ code: String) async throws -> Organization? {
        guard let model = try await OrganizationFluentModel.query(on: db)
            .filter(\.$code == code)
            .first() else {
            return nil
        }
        return model.toDomain()
    }
    
    public func existsByCode(_ code: String) async throws -> Bool {
        try await OrganizationFluentModel.query(on: db)
            .filter(\.$code == code)
            .first() != nil
    }
    
    public func create(code: String, name: String) async throws -> Organization {
        let model = OrganizationFluentModel(code: code, name: name)
        try await model.save(on: db)
        return model.toDomain()
    }
}

import Vapor
import Fluent

/// 组织数据访问对象
enum OrganizationDAO {
    /// 根据组织码查找组织
    static func findByCode(_ code: String, on db: any Database) async throws -> Organization? {
        try await Organization.query(on: db)
            .filter(\.$code == code)
            .first()
    }
    
    /// 检查组织码是否存在
    static func existsByCode(_ code: String, on db: any Database) async throws -> Bool {
        try await Organization.query(on: db)
            .filter(\.$code == code)
            .first() != nil
    }
    
    /// 创建组织
    static func createOrganization(code: String, name: String, on db: any Database) async throws -> Organization {
        let organization = Organization(code: code, name: name)
        try await organization.save(on: db)
        return organization
    }
}

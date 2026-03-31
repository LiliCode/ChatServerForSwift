import Foundation

/// 组织仓库接口
public protocol OrganizationRepository: Sendable {
    /// 根据组织码查找组织
    func findByCode(_ code: String) async throws -> Organization?
    
    /// 检查组织码是否存在
    func existsByCode(_ code: String) async throws -> Bool
    
    /// 创建组织
    func create(code: String, name: String) async throws -> Organization
}

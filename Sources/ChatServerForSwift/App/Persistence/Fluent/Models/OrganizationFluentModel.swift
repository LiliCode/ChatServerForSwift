import Vapor
import Fluent

/// Fluent 组织模型
final class OrganizationFluentModel: Model, Content, @unchecked Sendable {
    static let schema = "organizations"
    
    @ID(custom: "uid", generatedBy: .database)
    var id: Int?
    
    @Field(key: "code")
    var code: String
    
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: Int? = nil, code: String, name: String) {
        self.id = id
        self.code = code
        self.name = name
    }
}

// MARK: - 转换为领域实体

extension OrganizationFluentModel {
    func toDomain() -> Organization {
        Organization(
            id: id!,
            code: code,
            name: name
        )
    }
}

import Vapor
import Fluent

/// 组织表
final class Organization: Model, Content, @unchecked Sendable {
    static let schema = "organizations"
    
    /// 自增ID
    @ID(custom: "uid", generatedBy: .database)
    var id: Int?
    
    /// 组织码
    @Field(key: "code")
    var code: String
    
    /// 组织名称
    @Field(key: "name")
    var name: String
    
    init() { }
    
    init(id: Int? = nil, code: String, name: String) {
        self.id = id
        self.code = code
        self.name = name
    }
}

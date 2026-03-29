import Vapor
import Fluent

/// 用户表
final class User: Model, Content, Authenticatable, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    /// 用户名，注册时确定，唯一
    @Field(key: "username")
    var username: String
    
    /// 登录密码（存储哈希值）
    @Field(key: "password_hash")
    var passwordHash: String
    
    /// 用户昵称
    @Field(key: "nickname")
    var nickname: String
    
    /// 组织码
    @Field(key: "organization_code")
    var organizationCode: String
    
    /// 创建时间
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    /// 更新时间
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        username: String,
        passwordHash: String,
        nickname: String,
        organizationCode: String
    ) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.nickname = nickname
        self.organizationCode = organizationCode
    }
}

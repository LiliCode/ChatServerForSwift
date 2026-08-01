import Vapor
import Fluent

/// Fluent 用户模型
final class UserFluentModel: Model, Content, @unchecked Sendable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "nickname")
    var nickname: String
    
    @Field(key: "role")
    var role: String
    
    @OptionalField(key: "public_key")
    var publicKey: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        username: String,
        nickname: String,
        role: String
    ) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.role = role
    }
}

// MARK: - 转换为领域实体

extension UserFluentModel {
    func toDomain() -> User {
        User(
            id: id!,
            username: username,
            nickname: nickname,
            role: UserRole(rawValue: role) ?? .user,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}

extension User {
    func toFluentModel() -> UserFluentModel {
        UserFluentModel(
            id: id,
            username: username,
            nickname: nickname,
            role: role.rawValue
        )
    }
}

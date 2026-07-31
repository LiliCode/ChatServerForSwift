import Vapor
import Fluent

/// Fluent 会话令牌模型
final class TokenFluentModel: Model, @unchecked Sendable {
    static let schema = "tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "user_id")
    var userID: UUID
    
    @Field(key: "token")
    var token: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @OptionalField(key: "expires_at")
    var expiresAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        userID: UUID,
        token: String,
        expiresAt: Date?
    ) {
        self.id = id
        self.userID = userID
        self.token = token
        self.expiresAt = expiresAt
    }
}

extension TokenFluentModel {
    func toDomain() -> AuthToken {
        AuthToken(
            id: id!,
            userID: userID,
            token: token,
            createdAt: createdAt ?? Date(),
            expiresAt: expiresAt
        )
    }
}

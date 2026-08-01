import Vapor
import Fluent

/// Fluent 邀请码模型
final class InvitationCodeFluentModel: Model, Content, @unchecked Sendable {
    static let schema = "invitation_codes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "code")
    var code: String
    
    @Field(key: "created_by")
    var createdBy: UUID
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Field(key: "expires_at")
    var expiresAt: Date
    
    @OptionalField(key: "used_by")
    var usedBy: UUID?
    
    @OptionalField(key: "used_at")
    var usedAt: Date?
    
    init() { }
    
    init(
        id: UUID? = nil,
        code: String,
        createdBy: UUID,
        expiresAt: Date,
        usedBy: UUID? = nil,
        usedAt: Date? = nil
    ) {
        self.id = id
        self.code = code
        self.createdBy = createdBy
        self.expiresAt = expiresAt
        self.usedBy = usedBy
        self.usedAt = usedAt
    }
}

// MARK: - 转换为领域实体

extension InvitationCodeFluentModel {
    func toDomain() -> InvitationCode {
        InvitationCode(
            id: id!,
            code: code,
            createdBy: createdBy,
            createdAt: createdAt ?? Date(),
            expiresAt: expiresAt,
            usedBy: usedBy,
            usedAt: usedAt
        )
    }
}

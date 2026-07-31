import Fluent

/// 用户表迁移
struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .id()
            .field("username", .string, .required)
            .field("password_hash", .string, .required)
            .field("nickname", .string, .required)
            .field("organization_code", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "username")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
}

/// 组织表迁移
struct CreateOrganization: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("organizations")
            .field("uid", .int, .identifier(auto: true))
            .field("code", .string, .required)
            .field("name", .string, .required)
            .unique(on: "code")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("organizations").delete()
    }
}

/// 用户表新增公钥字段迁移（E2EE）
struct AddUserPublicKey: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .field("public_key", .string)
            .update()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users")
            .deleteField("public_key")
            .update()
    }
}

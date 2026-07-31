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

/// 删除用户表密码哈希列（助记词认证取代密码）
struct DropPasswordHash: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("users")
            .deleteField("password_hash")
            .update()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users")
            .field("password_hash", .string)
            .update()
    }
}

/// 会话令牌表迁移
struct CreateToken: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("tokens")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("token", .string, .required)
            .field("created_at", .datetime)
            .field("expires_at", .datetime)
            .unique(on: "token")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("tokens").delete()
    }
}

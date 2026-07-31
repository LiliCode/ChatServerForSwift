import Vapor
import Redis
import Fluent
import FluentSQLiteDriver

// configures your application
public func configure(_ app: Vapor.Application) async throws {
    // 错误映射中间件（领域/应用错误 → HTTP 状态码）
    app.middleware.use(AppErrorMiddleware())
    
    // 配置 Redis
    app.redis.configuration = try RedisConfiguration(hostname: "localhost")

    // 初始化数据库
    app.databases.use(.sqlite(.file("chat_server_db.sqlite")), as: .sqlite)
    
    // 添加迁移
    app.migrations.add(CreateUser())
    app.migrations.add(CreateOrganization())
    app.migrations.add(AddUserPublicKey())
    
    // 运行迁移
    try await app.autoMigrate()
    
    // 配置 WebSocket 连接管理器
    await WebSocketConnectionManager.shared.configure(messageCache: app.messageCache)
    
    // 初始化默认组织
    try await initializeDefaultOrganizations(on: app)

    // register routes
    try routes(app)
}

/// 初始化默认组织
private func initializeDefaultOrganizations(on app: Application) async throws {
    let repository = app.organizationRepository
    
    // 检查是否已有组织
    guard try await !repository.existsByCode("ORG001") else {
        return
    }
    
    app.logger.info("创建默认组织...")
    
    let defaultOrganizations = [
        (code: "ORG001", name: "默认组织"),
        (code: "ORG002", name: "测试组织"),
        (code: "ORG003", name: "开发组织")
    ]
    
    for org in defaultOrganizations {
        _ = try await repository.create(code: org.code, name: org.name)
        app.logger.info("组织码: \(org.code) - \(org.name)")
    }
}

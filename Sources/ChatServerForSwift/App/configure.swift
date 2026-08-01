import Vapor
import Redis
import Fluent
import FluentSQLiteDriver

// configures your application
public func configure(_ app: Vapor.Application) async throws {
    // 错误映射中间件（领域/应用错误 → HTTP 状态码）
    app.middleware.use(AppErrorMiddleware())
    
    // 配置 Redis（REDIS_PASSWORD 可选，生产环境建议设置）
    let redisHost = Environment.get("REDIS_HOST") ?? "localhost"
    app.redis.configuration = try RedisConfiguration(
        hostname: redisHost,
        password: Environment.get("REDIS_PASSWORD")
    )

    // 测试环境注入管理员引导密钥（生产环境必须显式设置 ADMIN_SETUP_SECRET）
    if app.environment == .testing {
        app.adminSetupSecret = "test-admin-secret"
    }

    // 初始化数据库（测试环境使用内存数据库，避免污染磁盘数据）
    if app.environment == .testing {
        app.databases.use(.sqlite(.memory), as: .sqlite)
    } else {
        let dbPath = Environment.get("DB_PATH") ?? "chat_server_db.sqlite"
        app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)
    }
    
    // 添加迁移
    app.migrations.add(CreateUser())
    app.migrations.add(CreateOrganization())
    app.migrations.add(AddUserPublicKey())
    app.migrations.add(DropPasswordHash())
    app.migrations.add(CreateToken())
    app.migrations.add(AddUserRole())
    app.migrations.add(DropUserOrganizationCode())
    app.migrations.add(CreateInvitationCodeTable())
    app.migrations.add(DropOrganizationTable())
    
    // 运行迁移
    try await app.autoMigrate()
    
    // 配置 WebSocket 连接管理器
    await WebSocketConnectionManager.shared.configure(messageCache: app.messageCache)

    // register routes
    try routes(app)
}

import Vapor
import Logging
import NIOCore
import NIOPosix
import Fluent
import FluentSQLiteDriver
import Redis

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)

        // This attempts to install NIO as the Swift Concurrency global executor.
        // You can enable it if you'd like to reduce the amount of context switching between NIO and Swift Concurrency.
        // Note: this has caused issues with some libraries that use `.wait()` and cleanly shutting down.
        // If enabled, you should be careful about calling async functions before this point as it can cause assertion failures.
        // let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
        // app.logger.debug("Tried to install SwiftNIO's EventLoopGroup as Swift's global concurrency executor", metadata: ["success": .stringConvertible(executorTakeoverSuccess)])
        
        do {
            // 错误映射中间件（领域/应用错误 → HTTP 状态码）
            app.middleware.use(AppErrorMiddleware())
            
            // 配置 Redis
            let redisHost = Environment.get("REDIS_HOST") ?? "localhost"
            app.redis.configuration = try RedisConfiguration(hostname: redisHost)

            // 初始化数据库
            let dbPath = Environment.get("DB_PATH") ?? "chat_server_db.sqlite"
            app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)
            
            // 添加迁移
            app.migrations.add(CreateUser())
            app.migrations.add(CreateOrganization())
            app.migrations.add(AddUserPublicKey())
            app.migrations.add(DropPasswordHash())
            app.migrations.add(CreateToken())
            
            // 运行迁移
            try await app.autoMigrate()
            
            // 配置 WebSocket 连接管理器
            await WebSocketConnectionManager.shared.configure(messageCache: RedisMessageCache(redis: app.redis))
            
            // 初始化默认组织
            try await initializeDefaultOrganizations(on: app)

            // register routes
            try routes(app)
            
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}

/// 初始化默认组织
private func initializeDefaultOrganizations(on app: Application) async throws {
    let repository = FluentOrganizationRepository(db: app.db)
    
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

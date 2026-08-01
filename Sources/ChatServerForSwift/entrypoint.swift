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
            
            // 配置 Redis（REDIS_PASSWORD 可选，生产环境建议设置）
            let redisHost = Environment.get("REDIS_HOST") ?? "localhost"
            app.redis.configuration = try RedisConfiguration(
                hostname: redisHost,
                password: Environment.get("REDIS_PASSWORD")
            )

            // 初始化数据库
            let dbPath = Environment.get("DB_PATH") ?? "chat_server_db.sqlite"
            app.databases.use(.sqlite(.file(dbPath)), as: .sqlite)
            
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
            await WebSocketConnectionManager.shared.configure(messageCache: RedisMessageCache(redis: app.redis))

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

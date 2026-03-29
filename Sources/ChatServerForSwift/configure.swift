import Vapor
import Redis
import Fluent
import FluentSQLiteDriver

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // 配置 Redis
    app.redis.configuration = try RedisConfiguration(hostname: "localhost")

    // 初始化数据库
    app.databases.use(.sqlite(.file("chat_server_db.sqlite")), as: .sqlite)
    
    // 添加迁移
    app.migrations.add(CreateUser())
    app.migrations.add(CreateOrganization())
    
    // 运行迁移
    try await app.autoMigrate()
    
    // 初始化默认组织（如果没有的话）
    try await initializeDefaultOrganizations(on: app)

    // register routes
    try routes(app)
}

/// 初始化默认组织
private func initializeDefaultOrganizations(on app: Application) async throws {
    let count = try await Organization.query(on: app.db).count()
    
    // 如果没有组织，创建一些默认的
    if count == 0 {
        app.logger.info("创建默认组织...")
        
        let defaultOrganizations = [
            (code: "ORG001", name: "默认组织"),
            (code: "ORG002", name: "测试组织"),
            (code: "ORG003", name: "开发组织")
        ]
        
        for org in defaultOrganizations {
            _ = try await OrganizationDAO.createOrganization(
                code: org.code,
                name: org.name,
                on: app.db
            )
            app.logger.info("组织码: \(org.code) - \(org.name)")
        }
    }
}

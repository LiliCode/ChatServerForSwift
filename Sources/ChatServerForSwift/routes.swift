import Vapor

func routes(_ app: Application) throws {
    // 健康检查
    app.get { req async in
        "Chat Server is running!"
    }
    
    app.get("health") { req async -> String in
        "OK"
    }
    
    // 注册 API 路由
    try app.register(collection: UserController())
    
    // 注册 WebSocket 路由
    try app.register(collection: ChatWebSocketController())
}

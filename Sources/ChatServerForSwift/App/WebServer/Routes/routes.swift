import Vapor

func routes(_ app: Application) throws {
    // 健康检查
    app.get { req async in
        "Chat Server is running!"
    }
    
    app.get("health") { req async -> String in
        "OK"
    }
    
    // 获取 Use Cases
    let registerUser = app.registerUser
    let loginUser = app.loginUser
    let changePassword = app.changePassword
    let changeNickname = app.changeNickname
    let getUserProfile = app.getUserProfile
    let sendMessage = app.sendMessage
    let processReceipt = app.processReceipt
    
    // 用户控制器
    let userController = UserController(
        registerUser: registerUser,
        loginUser: loginUser,
        changePassword: changePassword,
        changeNickname: changeNickname,
        getUserProfile: getUserProfile
    )
    try app.register(collection: userController)
    
    // WebSocket 控制器
    let connectionManager = WebSocketConnectionManager.shared
    let chatController = ChatWebSocketController(
        sendMessage: sendMessage,
        processReceipt: processReceipt,
        connectionManager: connectionManager
    )
    try app.register(collection: chatController)
}

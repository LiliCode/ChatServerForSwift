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
    let createAuthChallenge = app.createAuthChallenge
    let loginWithMnemonic = app.loginWithMnemonic
    let changeNickname = app.changeNickname
    let getUserProfile = app.getUserProfile
    let getPublicKey = app.getPublicKey
    let sendMessage = app.sendMessage
    let processReceipt = app.processReceipt
    
    // 认证中间件（不透明会话令牌）
    let authMiddleware = AuthMiddleware(tokenRepository: app.tokenRepository)
    
    // 用户控制器
    let userController = UserController(
        registerUser: registerUser,
        createAuthChallenge: createAuthChallenge,
        loginWithMnemonic: loginWithMnemonic,
        changeNickname: changeNickname,
        getUserProfile: getUserProfile,
        getPublicKey: getPublicKey,
        authMiddleware: authMiddleware
    )
    try app.register(collection: userController)
    
    // WebSocket 控制器
    let connectionManager = WebSocketConnectionManager.shared
    let chatController = ChatWebSocketController(
        sendMessage: sendMessage,
        processReceipt: processReceipt,
        connectionManager: connectionManager,
        tokenRepository: app.tokenRepository
    )
    try app.register(collection: chatController)
}

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
    let adminRegisterUser = app.adminRegisterUser
    let createInvitationCode = app.createInvitationCode
    let listInvitationCodes = app.listInvitationCodes
    let revokeInvitationCode = app.revokeInvitationCode
    let createAuthChallenge = app.createAuthChallenge
    let loginWithMnemonic = app.loginWithMnemonic
    let changeNickname = app.changeNickname
    let getUserProfile = app.getUserProfile
    let getPublicKey = app.getPublicKey
    let sendMessage = app.sendMessage
    let processReceipt = app.processReceipt
    
    // 认证中间件（不透明会话令牌）
    let authMiddleware = AuthMiddleware(tokenRepository: app.tokenRepository)
    let adminMiddleware = AdminMiddleware(userRepository: app.userRepository)
    
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
    
    // 后台管理控制器
    let adminController = AdminController(
        adminRegisterUser: adminRegisterUser,
        createInvitationCode: createInvitationCode,
        listInvitationCodes: listInvitationCodes,
        revokeInvitationCode: revokeInvitationCode,
        authMiddleware: authMiddleware,
        adminMiddleware: adminMiddleware
    )
    try app.register(collection: adminController)
    
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

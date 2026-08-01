import Vapor

/// 用户控制器
struct UserController: RouteCollection {
    private let registerUser: RegisterUser
    private let createAuthChallenge: CreateAuthChallenge
    private let loginWithMnemonic: LoginWithMnemonic
    private let changeNickname: ChangeNickname
    private let getUserProfile: GetUserProfile
    private let getPublicKey: GetPublicKey
    private let authMiddleware: AuthMiddleware
    
    init(
        registerUser: RegisterUser,
        createAuthChallenge: CreateAuthChallenge,
        loginWithMnemonic: LoginWithMnemonic,
        changeNickname: ChangeNickname,
        getUserProfile: GetUserProfile,
        getPublicKey: GetPublicKey,
        authMiddleware: AuthMiddleware
    ) {
        self.registerUser = registerUser
        self.createAuthChallenge = createAuthChallenge
        self.loginWithMnemonic = loginWithMnemonic
        self.changeNickname = changeNickname
        self.getUserProfile = getUserProfile
        self.getPublicKey = getPublicKey
        self.authMiddleware = authMiddleware
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "v1")
        
        // 公开接口
        api.post("register", use: register)
        api.post("auth", "challenge", use: createChallenge)
        api.post("auth", "login", use: mnemonicLogin)
        
        // 需要认证的接口
        let protected = api.grouped(authMiddleware)
        protected.get("profile", use: getProfile)
        protected.post("nickname", use: changeNicknameHandler)
        protected.get("keys", ":userID", use: getPublicKeyHandler)
    }
    
    // MARK: - 注册
    
    func register(req: Request) async throws -> UserResponseDTO {
        let input = try req.content.decode(RegisterUserInput.self)
        let userDTO = try await registerUser.execute(input)
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 登录挑战
    
    func createChallenge(req: Request) async throws -> AuthChallengeResponse {
        let input = try req.content.decode(AuthChallengeRequest.self)
        return try await createAuthChallenge.execute(username: input.username)
    }
    
    // MARK: - 助记词登录
    
    func mnemonicLogin(req: Request) async throws -> LoginResponseDTO {
        let input = try req.content.decode(MnemonicLoginRequest.self)
        let (token, userDTO) = try await loginWithMnemonic.execute(input)
        return LoginResponseDTO(token: token, user: userDTO)
    }
    
    // MARK: - 获取用户信息
    
    func getProfile(req: Request) async throws -> UserResponseDTO {
        let userID = try req.auth.require(UserID.self)
        let userDTO = try await getUserProfile.execute(userID: userID.value)
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 修改昵称
    
    func changeNicknameHandler(req: Request) async throws -> UserResponseDTO {
        let userID = try req.auth.require(UserID.self)
        let input = try req.content.decode(ChangeNicknameRequest.self)
        
        let useCaseInput = ChangeNicknameInput(
            userID: userID.value,
            newNickname: input.nickname
        )
        
        let userDTO = try await changeNickname.execute(useCaseInput)
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 获取公钥
    
    func getPublicKeyHandler(req: Request) async throws -> PublicKeyResponseDTO {
        guard let targetUserIDString = req.parameters.get("userID"),
              let targetUserID = UUID(uuidString: targetUserIDString) else {
            throw Abort(.badRequest, reason: "无效的用户ID")
        }
        
        let publicKey = try await getPublicKey.execute(userID: targetUserID)
        return PublicKeyResponseDTO(userID: targetUserIDString, publicKey: publicKey)
    }
}

// MARK: - Request/Response DTOs

public struct ChangeNicknameRequest: Content {
    let nickname: String
}

public struct UserResponseDTO: Content {
    let id: String
    let username: String
    let nickname: String
    let role: String
    let createdAt: Date?
    
    init(from dto: UserDTO) {
        self.id = dto.id
        self.username = dto.username
        self.nickname = dto.nickname
        self.role = dto.role
        self.createdAt = dto.createdAt
    }
}

// MARK: - UserID

struct UserID: Authenticatable, Sendable {
    let value: UUID
}

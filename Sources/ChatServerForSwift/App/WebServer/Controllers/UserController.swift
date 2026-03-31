import Vapor

/// 用户控制器
struct UserController: RouteCollection {
    private let registerUser: RegisterUser
    private let loginUser: LoginUser
    private let changePassword: ChangePassword
    private let changeNickname: ChangeNickname
    private let getUserProfile: GetUserProfile
    
    init(
        registerUser: RegisterUser,
        loginUser: LoginUser,
        changePassword: ChangePassword,
        changeNickname: ChangeNickname,
        getUserProfile: GetUserProfile
    ) {
        self.registerUser = registerUser
        self.loginUser = loginUser
        self.changePassword = changePassword
        self.changeNickname = changeNickname
        self.getUserProfile = getUserProfile
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "v1")
        
        // 公开接口
        api.post("register", use: register)
        api.post("login", use: login)
        
        // 需要认证的接口
        let protected = api.grouped(AuthMiddleware())
        protected.get("profile", use: getProfile)
        protected.post("password", use: changePasswordHandler)
        protected.post("nickname", use: changeNicknameHandler)
    }
    
    // MARK: - 注册
    
    func register(req: Request) async throws -> UserResponseDTO {
        let input = try req.content.decode(RegisterUserInput.self)
        let userDTO = try await registerUser.execute(input)
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 登录
    
    func login(req: Request) async throws -> UserResponseDTO {
        let input = try req.content.decode(LoginUserInput.self)
        let (userDTO, _) = try await loginUser.execute(input)
        
        // 将用户ID存入 header
        req.headers.add(name: "X-User-ID", value: userDTO.id)
        
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 获取用户信息
    
    func getProfile(req: Request) async throws -> UserResponseDTO {
        let userID = try req.auth.require(UserID.self)
        let userDTO = try await getUserProfile.execute(userID: userID.value)
        return UserResponseDTO(from: userDTO)
    }
    
    // MARK: - 修改密码
    
    func changePasswordHandler(req: Request) async throws -> Response {
        let userID = try req.auth.require(UserID.self)
        let input = try req.content.decode(ChangePasswordRequest.self)
        
        let useCaseInput = ChangePasswordInput(
            userID: userID.value,
            oldPassword: input.oldPassword,
            newPassword: input.newPassword
        )
        
        try await changePassword.execute(useCaseInput)
        
        return Response(status: .ok, body: .init(string: "密码修改成功"))
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
}

// MARK: - Request/Response DTOs

public struct ChangePasswordRequest: Content {
    let oldPassword: String
    let newPassword: String
}

public struct ChangeNicknameRequest: Content {
    let nickname: String
}

public struct UserResponseDTO: Content {
    let id: String
    let username: String
    let nickname: String
    let organizationCode: String
    let createdAt: Date?
    
    init(from dto: UserDTO) {
        self.id = dto.id
        self.username = dto.username
        self.nickname = dto.nickname
        self.organizationCode = dto.organizationCode
        self.createdAt = dto.createdAt
    }
}

// MARK: - UserID

struct UserID: Authenticatable, Sendable {
    let value: UUID
}

import Foundation

/// 管理员注册用例（凭管理员密钥创建管理员账号，用于首次引导）
public struct AdminRegisterUser: Sendable {
    private let userRepository: any UserRepository
    private let keyRepository: any KeyRepository
    private let expectedSecret: String?
    
    public init(
        userRepository: any UserRepository,
        keyRepository: any KeyRepository,
        expectedSecret: String?
    ) {
        self.userRepository = userRepository
        self.keyRepository = keyRepository
        self.expectedSecret = expectedSecret
    }
    
    public func execute(_ input: AdminRegisterUserInput) async throws -> UserDTO {
        // 1. 校验管理员密钥是否已配置
        guard let expectedSecret = expectedSecret else {
            throw ApplicationError.adminSecretNotConfigured
        }
        
        // 2. 校验管理员密钥
        guard AdminRegisterUser.constantTimeEqual(expectedSecret, input.adminSecret) else {
            throw ApplicationError.adminSecretInvalid
        }
        
        // 3. 验证用户名
        _ = try Username(input.username)
        
        // 4. 验证公钥格式（base64 32字节）
        _ = try PublicKey(input.publicKey)
        
        // 5. 检查用户名是否已存在
        guard try await !userRepository.existsByUsername(input.username) else {
            throw ApplicationError.usernameAlreadyExists
        }
        
        // 6. 创建管理员用户
        let now = Date()
        let user = User(
            id: UUID(),
            username: input.username,
            nickname: input.username,
            role: .admin,
            createdAt: now,
            updatedAt: now
        )
        
        let createdUser = try await userRepository.create(user)
        
        // 7. 绑定公钥
        try await keyRepository.upsertPublicKey(input.publicKey, for: createdUser.id)
        
        return UserDTO(user: createdUser)
    }
    
    static func constantTimeEqual(_ lhs: String, _ rhs: String) -> Bool {
        let lhsData = Data(lhs.utf8)
        let rhsData = Data(rhs.utf8)
        guard lhsData.count == rhsData.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<lhsData.count {
            diff |= lhsData[i] ^ rhsData[i]
        }
        return diff == 0
    }
}

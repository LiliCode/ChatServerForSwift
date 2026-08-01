import Foundation

/// 注册用户用例（注册时即绑定 E2EE 公钥，助记词认证取代密码）
public struct RegisterUser: Sendable {
    private let userRepository: any UserRepository
    private let invitationCodeRepository: any InvitationCodeRepository
    private let keyRepository: any KeyRepository
    
    public init(
        userRepository: any UserRepository,
        invitationCodeRepository: any InvitationCodeRepository,
        keyRepository: any KeyRepository
    ) {
        self.userRepository = userRepository
        self.invitationCodeRepository = invitationCodeRepository
        self.keyRepository = keyRepository
    }
    
    public func execute(_ input: RegisterUserInput) async throws -> UserDTO {
        // 1. 验证用户名
        _ = try Username(input.username)
        
        // 2. 验证邀请码
        let invitationValue = try InvitationCodeValue(input.invitationCode)
        
        // 3. 验证公钥格式（base64 32字节）
        _ = try PublicKey(input.publicKey)
        
        // 4. 校验邀请码真实有效（存在、未过期、未使用）
        guard let invitation = try await invitationCodeRepository.findByCode(invitationValue.value) else {
            throw ApplicationError.invitationCodeNotFound
        }
        guard !invitation.isExpired else {
            throw ApplicationError.invitationCodeExpired
        }
        guard !invitation.isUsed else {
            throw ApplicationError.invitationCodeUsed
        }
        
        // 5. 检查用户名是否已存在
        guard try await !userRepository.existsByUsername(input.username) else {
            throw ApplicationError.usernameAlreadyExists
        }
        
        // 6. 创建用户（默认普通用户角色）
        let now = Date()
        let user = User(
            id: UUID(),
            username: input.username,
            nickname: input.username,
            role: .user,
            createdAt: now,
            updatedAt: now
        )
        
        let createdUser = try await userRepository.create(user)
        
        // 7. 标记邀请码已被使用（单次使用）
        try await invitationCodeRepository.markUsed(code: invitation.code, usedBy: createdUser.id)
        
        // 8. 绑定公钥到新账号
        try await keyRepository.upsertPublicKey(input.publicKey, for: createdUser.id)
        
        return UserDTO(user: createdUser)
    }
}

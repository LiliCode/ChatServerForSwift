import Foundation

/// 注册用户用例
public struct RegisterUser: Sendable {
	private let userRepository: any UserRepository
	private let orgRepository: any OrganizationRepository
    
    public init(
		userRepository: any UserRepository,
		orgRepository: any OrganizationRepository
    ) {
        self.userRepository = userRepository
        self.orgRepository = orgRepository
    }
    
    public func execute(_ input: RegisterUserInput) async throws -> UserDTO {
        // 1. 验证用户名
        _ = try Username(input.username)
        
        // 2. 验证密码
        let password = try Password(input.password)
        
        // 3. 验证组织码
        _ = try OrganizationCode(input.organizationCode)
        
        // 4. 检查组织码是否存在
        guard try await orgRepository.existsByCode(input.organizationCode) else {
            throw ApplicationError.organizationNotFound
        }
        
        // 5. 检查用户名是否已存在
        guard try await !userRepository.existsByUsername(input.username) else {
            throw ApplicationError.usernameAlreadyExists
        }
        
        // 6. 创建用户
        let now = Date()
        let user = User(
            id: UUID(),
            username: input.username,
            nickname: input.username,
            organizationCode: input.organizationCode,
            createdAt: now,
            updatedAt: now
        )
        
        let createdUser = try await userRepository.create(
            user,
            passwordHash: password.hash()
        )
        
        return UserDTO(
            id: createdUser.id.uuidString,
            username: createdUser.username,
            nickname: createdUser.nickname,
            organizationCode: createdUser.organizationCode,
            createdAt: createdUser.createdAt
        )
    }
}

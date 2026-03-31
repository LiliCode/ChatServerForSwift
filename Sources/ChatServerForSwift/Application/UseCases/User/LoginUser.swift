import Foundation

/// 用户登录用例
public struct LoginUser: Sendable {
    private let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    /// 执行登录，返回用户DTO和密码哈希（用于后续认证）
    public func execute(_ input: LoginUserInput) async throws -> (user: UserDTO, passwordHash: String) {
        // 1. 查找用户
        guard let user = try await userRepository.findByUsername(input.username) else {
            throw ApplicationError.invalidCredentials
        }
        
        // 2. 获取密码哈希（通过仓库获取）
        let hash = try await userRepository.getPasswordHash(for: user.id)
        
        // 3. 验证密码
        let password = try Password(input.password)
        guard password.verify(against: hash) else {
            throw ApplicationError.invalidCredentials
        }
        
        let userDTO = UserDTO(
            id: user.id.uuidString,
            username: user.username,
            nickname: user.nickname,
            organizationCode: user.organizationCode,
            createdAt: user.createdAt
        )
        
        return (userDTO, hash)
    }
}

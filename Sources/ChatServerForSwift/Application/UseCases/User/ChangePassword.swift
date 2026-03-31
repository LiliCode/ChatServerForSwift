import Foundation

/// 修改密码用例
public struct ChangePassword: Sendable {
	private let userRepository: any UserRepository
    
	public init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }
    
    public func execute(_ input: ChangePasswordInput) async throws {
        // 1. 查找用户
        guard let user = try await userRepository.findByID(input.userID) else {
            throw ApplicationError.userNotFound
        }
        
        // 2. 获取当前密码哈希
        let currentHash = try await userRepository.getPasswordHash(for: user.id)
        
        // 3. 验证旧密码
        let oldPassword = try Password(input.oldPassword)
        guard oldPassword.verify(against: currentHash) else {
            throw ApplicationError.invalidOldPassword
        }
        
        // 4. 验证新密码
        let newPassword = try Password(input.newPassword)
        
        // 5. 更新密码
        try await userRepository.updatePassword(
            userID: user.id,
            newHash: newPassword.hash()
        )
    }
}

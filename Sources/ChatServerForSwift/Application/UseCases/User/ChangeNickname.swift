import Foundation

/// 修改昵称用例
public struct ChangeNickname: Sendable {
    private let userRepository: UserRepository
    
    public init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    public func execute(_ input: ChangeNicknameInput) async throws -> UserDTO {
        // 1. 查找用户
        guard let user = try await userRepository.findByID(input.userID) else {
            throw ApplicationError.userNotFound
        }
        
        // 2. 验证新昵称
        let nickname = try Nickname(input.newNickname)
        
        // 3. 更新昵称
        try await userRepository.updateNickname(
            userID: user.id,
            newNickname: nickname.value
        )
        
        // 4. 返回更新后的用户信息
        let updatedUser = try await userRepository.findByID(user.id)!
        
        return UserDTO(
            id: updatedUser.id.uuidString,
            username: updatedUser.username,
            nickname: updatedUser.nickname,
            organizationCode: updatedUser.organizationCode,
            createdAt: updatedUser.createdAt
        )
    }
}

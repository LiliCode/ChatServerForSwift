import Foundation

/// 获取用户资料用例
public struct GetUserProfile: Sendable {
	private let userRepository: any UserRepository
    
	public init(userRepository: any UserRepository) {
        self.userRepository = userRepository
    }
    
    public func execute(userID: UUID) async throws -> UserDTO {
        guard let user = try await userRepository.findByID(userID) else {
            throw ApplicationError.userNotFound
        }
        
        return UserDTO(
            id: user.id.uuidString,
            username: user.username,
            nickname: user.nickname,
            organizationCode: user.organizationCode,
            createdAt: user.createdAt
        )
    }
}

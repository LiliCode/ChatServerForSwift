import Foundation

/// 获取用户公钥用例（E2EE 密钥恢复）
public struct GetPublicKey: Sendable {
    private let keyRepository: any KeyRepository
    
    public init(keyRepository: any KeyRepository) {
        self.keyRepository = keyRepository
    }
    
    public func execute(userID: UUID) async throws -> String? {
        try await keyRepository.findPublicKey(for: userID)
    }
}

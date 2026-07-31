import Foundation

/// 上传公钥用例（E2EE 密钥恢复）
public struct UploadPublicKey: Sendable {
    private let keyRepository: any KeyRepository
    
    public init(keyRepository: any KeyRepository) {
        self.keyRepository = keyRepository
    }
    
    public func execute(_ input: UploadPublicKeyInput) async throws {
        // 1. 验证公钥格式
        _ = try PublicKey(input.publicKey)
        
        // 2. 保存公钥
        try await keyRepository.upsertPublicKey(input.publicKey, for: input.userID)
    }
}

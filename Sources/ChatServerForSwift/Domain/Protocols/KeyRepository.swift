import Foundation

/// 用户公钥仓库接口（E2EE 公钥管理）
public protocol KeyRepository: Sendable {
    /// 获取用户公钥
    func findPublicKey(for userID: UUID) async throws -> String?
    
    /// 保存或更新用户公钥
    func upsertPublicKey(_ publicKey: String, for userID: UUID) async throws
}

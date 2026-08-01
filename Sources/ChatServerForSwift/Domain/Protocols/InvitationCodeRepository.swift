import Foundation

/// 邀请码仓库接口
public protocol InvitationCodeRepository: Sendable {
    /// 根据邀请码查找
    func findByCode(_ code: String) async throws -> InvitationCode?
    
    /// 创建邀请码
    func create(code: String, createdBy: UUID, expiresAt: Date) async throws -> InvitationCode
    
    /// 标记邀请码已被某用户使用（单次使用）
    func markUsed(code: String, usedBy: UUID) async throws
    
    /// 列表
    func list() async throws -> [InvitationCode]
    
    /// 撤销邀请码
    func revoke(code: String) async throws
}

import Foundation

/// 生成邀请码用例（仅管理员可调用）
public struct CreateInvitationCode: Sendable {
    private let invitationCodeRepository: any InvitationCodeRepository
    
    public init(invitationCodeRepository: any InvitationCodeRepository) {
        self.invitationCodeRepository = invitationCodeRepository
    }
    
    public func execute(_ input: CreateInvitationCodeInput) async throws -> InvitationCodeDTO {
        guard input.expiresAt > Date() else {
            throw ApplicationError.validationError("过期时间必须晚于当前时间")
        }
        
        // 生成唯一邀请码
        let code = try await generateUniqueCode()
        let invitation = try await invitationCodeRepository.create(
            code: code,
            createdBy: input.createdBy,
            expiresAt: input.expiresAt
        )
        
        return InvitationCodeDTO(invitation: invitation)
    }
    
    /// 生成 12 位字母数字邀请码，确保数据库中唯一
    private func generateUniqueCode() async throws -> String {
        let allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        for _ in 0..<10 {
            var code = ""
            for _ in 0..<12 {
                let index = Int.random(in: 0..<allowed.count)
                code.append(allowed[allowed.index(allowed.startIndex, offsetBy: index)])
            }
            if try await invitationCodeRepository.findByCode(code) == nil {
                return code
            }
        }
        throw ApplicationError.validationError("生成邀请码失败，请重试")
    }
}

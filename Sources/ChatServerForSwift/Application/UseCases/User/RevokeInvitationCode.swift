import Foundation

/// 撤销邀请码用例（仅管理员可调用）
public struct RevokeInvitationCode: Sendable {
    private let invitationCodeRepository: any InvitationCodeRepository
    
    public init(invitationCodeRepository: any InvitationCodeRepository) {
        self.invitationCodeRepository = invitationCodeRepository
    }
    
    public func execute(_ input: RevokeInvitationCodeInput) async throws {
        let code = try InvitationCodeValue(input.code)
        guard try await invitationCodeRepository.findByCode(code.value) != nil else {
            throw ApplicationError.invitationCodeNotFound
        }
        try await invitationCodeRepository.revoke(code: code.value)
    }
}

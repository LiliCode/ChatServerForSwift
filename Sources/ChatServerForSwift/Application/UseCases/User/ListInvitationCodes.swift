import Foundation

/// 邀请码列表用例（仅管理员可调用）
public struct ListInvitationCodes: Sendable {
    private let invitationCodeRepository: any InvitationCodeRepository
    
    public init(invitationCodeRepository: any InvitationCodeRepository) {
        self.invitationCodeRepository = invitationCodeRepository
    }
    
    public func execute() async throws -> [InvitationCodeDTO] {
        let invitations = try await invitationCodeRepository.list()
        return invitations
            .sorted { $0.createdAt > $1.createdAt }
            .map { InvitationCodeDTO(invitation: $0) }
    }
}

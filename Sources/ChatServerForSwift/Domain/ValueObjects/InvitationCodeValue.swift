import Foundation

/// 邀请码值对象
public struct InvitationCodeValue: Sendable {
    public let value: String
    
    public init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw DomainError.validationError("邀请码不能为空")
        }
        self.value = trimmed
    }
}

import Foundation

/// 组织码值对象
public struct OrganizationCode: Sendable {
    public let value: String
    
    public init(_ value: String) throws {
        guard !value.isEmpty else {
            throw DomainError.validationError("组织码不能为空")
        }
        self.value = value
    }
}

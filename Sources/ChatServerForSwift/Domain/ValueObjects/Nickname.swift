import Foundation

/// 昵称值对象
public struct Nickname: Sendable {
    public let value: String
    
    public init(_ value: String) throws {
        guard value.count >= 1 else {
            throw DomainError.validationError("昵称至少需要1个字符")
        }
        guard value.count <= 20 else {
            throw DomainError.validationError("昵称不能超过20个字符")
        }
        self.value = value
    }
}

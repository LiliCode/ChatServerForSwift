import Foundation

/// 用户名值对象
public struct Username: Sendable {
    public let value: String
    
    public init(_ value: String) throws {
        guard value.count >= 3 else {
            throw DomainError.validationError("用户名至少需要3个字符")
        }
        guard value.count <= 20 else {
            throw DomainError.validationError("用户名不能超过20个字符")
        }
        // 只允许字母、数字、下划线
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard value.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw DomainError.validationError("用户名只能包含字母、数字和下划线")
        }
        self.value = value
    }
}

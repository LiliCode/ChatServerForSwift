import Foundation
import CryptoKit

/// 密码值对象
public struct Password: Sendable {
    public let value: String
    
    public init(_ value: String) throws {
        guard value.count >= 6 else {
            throw DomainError.validationError("密码至少需要6个字符")
        }
        self.value = value
    }
    
    /// 哈希密码
    public func hash() -> String {
        PasswordHasher.hash(value)
    }
    
    /// 验证密码是否匹配哈希
    public func verify(against hash: String) -> Bool {
        PasswordHasher.verify(value, against: hash)
    }
}

/// 密码哈希工具
public enum PasswordHasher {
    public static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    public static func verify(_ password: String, against hash: String) -> Bool {
        Self.hash(password) == hash
    }
}

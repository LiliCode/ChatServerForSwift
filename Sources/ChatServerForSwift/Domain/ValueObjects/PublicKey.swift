import Foundation

/// 用户公钥值对象（base64 编码的 X25519 公钥）
public struct PublicKey: Sendable {
    public let value: String
    
    public init(_ value: String) throws {
        guard let data = Data(base64Encoded: value), data.count == 32 else {
            throw DomainError.validationError("公钥必须是 base64 编码的 32 字节数据")
        }
        self.value = value
    }
}

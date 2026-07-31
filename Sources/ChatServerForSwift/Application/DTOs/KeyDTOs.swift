import Foundation
import Vapor

// MARK: - Input DTOs

/// 上传公钥输入
public struct UploadPublicKeyInput: Sendable {
    public let userID: UUID
    public let publicKey: String
    
    public init(userID: UUID, publicKey: String) {
        self.userID = userID
        self.publicKey = publicKey
    }
}

// MARK: - Request/Response DTOs

/// 上传公钥请求
public struct UploadPublicKeyRequest: Content {
    public let publicKey: String
    
    public init(publicKey: String) {
        self.publicKey = publicKey
    }
}

/// 公钥响应 DTO
public struct PublicKeyResponseDTO: Content {
    public let userID: String
    public let publicKey: String?
    
    public init(userID: String, publicKey: String?) {
        self.userID = userID
        self.publicKey = publicKey
    }
}

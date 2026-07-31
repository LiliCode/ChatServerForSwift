import Foundation
import Vapor

// MARK: - Response DTOs

/// 公钥响应 DTO
public struct PublicKeyResponseDTO: Content {
    public let userID: String
    public let publicKey: String?
    
    public init(userID: String, publicKey: String?) {
        self.userID = userID
        self.publicKey = publicKey
    }
}

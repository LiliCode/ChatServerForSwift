import Foundation
import Vapor

// MARK: - 登录挑战

/// 发起登录挑战请求
public struct AuthChallengeRequest: Content {
    public let username: String
    
    public init(username: String) {
        self.username = username
    }
}

/// 登录挑战响应
public struct AuthChallengeResponse: Content {
    public let nonce: String
    public let ephemeralPublicKey: String
    
    public init(nonce: String, ephemeralPublicKey: String) {
        self.nonce = nonce
        self.ephemeralPublicKey = ephemeralPublicKey
    }
}

/// 助记词登录请求（X25519 DH 挑战-响应）
public struct MnemonicLoginRequest: Content {
    public let username: String
    public let nonce: String
    public let proof: String
    
    public init(username: String, nonce: String, proof: String) {
        self.username = username
        self.nonce = nonce
        self.proof = proof
    }
}

// MARK: - 登录响应

/// 登录响应（会话令牌 + 用户信息）
public struct LoginResponseDTO: Content {
    public let token: String
    public let id: String
    public let username: String
    public let nickname: String
    public let organizationCode: String
    public let createdAt: Date?
    
    public init(token: String, user: UserDTO) {
        self.token = token
        self.id = user.id
        self.username = user.username
        self.nickname = user.nickname
        self.organizationCode = user.organizationCode
        self.createdAt = user.createdAt
    }
}

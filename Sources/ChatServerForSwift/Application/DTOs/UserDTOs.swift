import Foundation
import Vapor

// MARK: - Input DTOs

/// 注册用户输入（助记词派生密钥对，注册即绑定公钥）
public struct RegisterUserInput: Content, Sendable {
    public let username: String
    public let organizationCode: String
    public let publicKey: String
    
    public init(username: String, organizationCode: String, publicKey: String) {
        self.username = username
        self.organizationCode = organizationCode
        self.publicKey = publicKey
    }
}

/// 修改昵称输入
public struct ChangeNicknameInput: Sendable {
    public let userID: UUID
    public let newNickname: String
    
    public init(userID: UUID, newNickname: String) {
        self.userID = userID
        self.newNickname = newNickname
    }
}

// MARK: - Output DTOs

/// 用户响应 DTO
public struct UserDTO: Sendable {
    public let id: String
    public let username: String
    public let nickname: String
    public let organizationCode: String
    public let createdAt: Date?
    
    public init(
        id: String,
        username: String,
        nickname: String,
        organizationCode: String,
        createdAt: Date?
    ) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.organizationCode = organizationCode
        self.createdAt = createdAt
    }
}

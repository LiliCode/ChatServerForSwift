import Foundation
import Vapor

// MARK: - Input DTOs

/// 注册用户输入（助记词派生密钥对，注册即绑定公钥）
public struct RegisterUserInput: Content, Sendable {
    public let username: String
    public let invitationCode: String
    public let publicKey: String
    
    public init(username: String, invitationCode: String, publicKey: String) {
        self.username = username
        self.invitationCode = invitationCode
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
    public let role: String
    public let createdAt: Date?
    
    public init(
        id: String,
        username: String,
        nickname: String,
        role: String,
        createdAt: Date?
    ) {
        self.id = id
        self.username = username
        self.nickname = nickname
        self.role = role
        self.createdAt = createdAt
    }
    
    public init(user: User) {
        self.id = user.id.uuidString
        self.username = user.username
        self.nickname = user.nickname
        self.role = user.role.rawValue
        self.createdAt = user.createdAt
    }
}

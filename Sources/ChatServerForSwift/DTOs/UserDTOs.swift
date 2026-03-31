import Foundation
import Vapor

// MARK: - Input DTOs

/// 注册用户输入
public struct RegisterUserInput: Content, Sendable {
    public let username: String
    public let password: String
    public let organizationCode: String
    
    public init(username: String, password: String, organizationCode: String) {
        self.username = username
        self.password = password
        self.organizationCode = organizationCode
    }
}

/// 登录用户输入
public struct LoginUserInput: Content, Sendable {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

/// 修改密码输入
public struct ChangePasswordInput: Sendable {
    public let userID: UUID
    public let oldPassword: String
    public let newPassword: String
    
    public init(userID: UUID, oldPassword: String, newPassword: String) {
        self.userID = userID
        self.oldPassword = oldPassword
        self.newPassword = newPassword
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

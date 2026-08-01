import Foundation

/// 用户角色
public enum UserRole: String, Sendable, Codable {
    case user
    case admin
    
    /// 是否为管理员
    public var isAdmin: Bool {
        self == .admin
    }
}

import Foundation

/// 组织领域实体
public struct Organization: Sendable, Identifiable {
    public let id: Int
    public let code: String
    public let name: String
    
    public init(
        id: Int,
        code: String,
        name: String
    ) {
        self.id = id
        self.code = code
        self.name = name
    }
}

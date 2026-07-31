import Foundation

/// 登录挑战存储（内存实现，TTL 5 分钟，单次使用）
public actor AuthChallengeStore {
    public static let shared = AuthChallengeStore()
    
    private struct Entry {
        let username: String
        let privateKey: Data
        let createdAt: Date
    }
    
    private var entries: [String: Entry] = [:]
    private let ttl: TimeInterval = 300
    
    private init() {}
    
    public func store(nonce: String, username: String, privateKey: Data) {
        cleanExpired()
        entries[nonce] = Entry(username: username, privateKey: privateKey, createdAt: Date())
    }
    
    /// 取出并销毁挑战（一次性使用，防重放）
    public func take(nonce: String) -> (username: String, privateKey: Data)? {
        cleanExpired()
        guard let entry = entries.removeValue(forKey: nonce) else { return nil }
        return (entry.username, entry.privateKey)
    }
    
    private func cleanExpired() {
        let now = Date()
        entries = entries.filter { now.timeIntervalSince($0.value.createdAt) < ttl }
    }
}

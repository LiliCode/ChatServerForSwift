@preconcurrency import Vapor
@preconcurrency import Redis
import Foundation
import NIOCore

/// WebSocket 连接信息
struct WebSocketConnection: @unchecked Sendable {
    let userID: UUID
    let socket: WebSocket
    let connectedAt: Date
}

/// 聊天 WebSocket 管理器
actor ChatWebSocketManager {
    /// 单例
    static let shared = ChatWebSocketManager()
    
    /// 用户ID到WebSocket连接的映射
    private var connections: [UUID: WebSocketConnection] = [:]
    
    /// Redis 离线消息键前缀
    private let offlineMessageKeyPrefix = "offline:msg:"
    
    private init() {}
    
    // MARK: - 连接管理
    
    /// 添加连接
    func addConnection(userID: UUID, socket: WebSocket) {
        let connection = WebSocketConnection(
            userID: userID,
            socket: socket,
            connectedAt: Date()
        )
        connections[userID] = connection
    }
    
    /// 移除连接
    func removeConnection(userID: UUID) {
        connections.removeValue(forKey: userID)
    }
    
    /// 获取连接
    func getConnection(userID: UUID) -> WebSocketConnection? {
        connections[userID]
    }
    
    /// 检查用户是否在线
    func isUserOnline(userID: UUID) -> Bool {
        connections[userID] != nil
    }
    
    // MARK: - 消息发送
    
    /// 发送消息给指定用户
    func sendMessage(to userID: UUID, message: PushMessage, on req: Request) async throws {
        let messageData = try message.serializedData()
        
        if let connection = connections[userID] {
            // 用户在线，直接发送
            try await connection.socket.send(raw: messageData, opcode: .binary)
        } else {
            // 用户离线，缓存到 Redis
            try await cacheOfflineMessage(for: userID, message: message, on: req)
        }
    }
    
    /// 推送离线消息给用户
    func pushOfflineMessages(to userID: UUID, on req: Request) async throws {
        let key = offlineMessageKey(for: userID)
        
        // 获取所有离线消息
        let messages: [RESPValue] = try await req.redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        
        guard !messages.isEmpty else { return }
        
        // 发送消息
        if let connection = connections[userID] {
            for messageData in messages {
                if let data = extractData(from: messageData) {
                    try await connection.socket.send(raw: data, opcode: .binary)
                }
            }
			
            // 清空离线消息
            let _ = try await req.redis.delete(key).get()
        }
    }
    
    // MARK: - 离线消息缓存
    
    /// 缓存离线消息
    private func cacheOfflineMessage(for userID: UUID, message: PushMessage, on req: Request) async throws {
        let key = offlineMessageKey(for: userID)
        let messageData = try message.serializedData()
        
        // 使用 RPUSH 将消息添加到列表末尾
        _ = try await req.redis.rpush(messageData, into: key).get()
    }
    
    /// 删除已确认的离线消息
    func removeConfirmedMessage(userID: UUID, messageHash: String, on req: Request) async throws {
        let key = offlineMessageKey(for: userID)
        
        // 获取所有离线消息
        let messages: [RESPValue] = try await req.redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        
        for (index, messageData) in messages.enumerated() {
            guard let data = extractData(from: messageData) else { continue }
            
            // 解析消息，检查 hash
            if let message = try? PushMessage(serializedBytes: data),
               message.hash == messageHash {
                // 删除该消息（通过设置为空值然后清理）
                // Redis 列表不支持直接删除指定索引，这里使用 LSET + LREM 的方式
                let emptyData = Data()
                let emptyRESPValue = RESPValue(from: emptyData)
                _ = try await req.redis.lset(index: index, to: emptyRESPValue, in: key).get()
                _ = try await req.redis.lrem(emptyData, from: key, count: 0).get()
                break
            }
        }
    }
    
    /// 从 RESPValue 提取 Data
    private func extractData(from value: RESPValue) -> Data? {
        switch value {
        case .bulkString(let buffer):
            guard let buffer = buffer else { return nil }
            return buffer.getData(at: 0, length: buffer.readableBytes)
        case .simpleString(let buffer):
            return buffer.getData(at: 0, length: buffer.readableBytes)
        default:
            return nil
        }
    }
    
    /// 生成 Redis 键
    private func offlineMessageKey(for userID: UUID) -> RedisKey {
        RedisKey("\(offlineMessageKeyPrefix)\(userID.uuidString)")
    }
}

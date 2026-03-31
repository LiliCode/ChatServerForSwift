@preconcurrency import Vapor
@preconcurrency import Redis
import Foundation

/// Redis 消息缓存实现
public struct RedisMessageCache: MessageCache {
    private let redis: any RedisClient
    private let offlineMessageKeyPrefix = "offline:msg:"
    
    public init(redis: any RedisClient) {
        self.redis = redis
    }
    
    public func cacheOfflineMessage(for userID: UUID, message: ChatMessage) async throws {
        let key = offlineMessageKey(for: userID)
        let messageData = try encodeMessage(message)
        _ = try await redis.rpush(messageData, into: key).get()
    }
    
    public func fetchAndClearOfflineMessages(for userID: UUID) async throws -> [ChatMessage] {
        let key = offlineMessageKey(for: userID)
        
        // 获取所有消息
        let messages: [RESPValue] = try await redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        
        // 解码消息
        var result: [ChatMessage] = []
        for value in messages {
            if let data = extractData(from: value),
               let message = try? decodeMessage(data) {
                result.append(message)
            }
        }
        
        // 清空缓存
        _ = try await redis.delete(key).get()
        
        return result
    }
    
    public func removeConfirmedMessage(userID: UUID, messageID: String) async throws {
        let key = offlineMessageKey(for: userID)
        
        let messages: [RESPValue] = try await redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        
        for (index, value) in messages.enumerated() {
            guard let data = extractData(from: value),
                  let message = try? decodeMessage(data),
                  message.id == messageID else {
                continue
            }
            
            // 使用 LSET + LREM 删除指定消息
            let emptyData = Data()
            let emptyRESPValue = RESPValue(from: emptyData)
            _ = try await redis.lset(index: index, to: emptyRESPValue, in: key).get()
            _ = try await redis.lrem(emptyData, from: key, count: 0).get()
            break
        }
    }
    
    // MARK: - Private Helpers
    
    private func offlineMessageKey(for userID: UUID) -> RedisKey {
        RedisKey("\(offlineMessageKeyPrefix)\(userID.uuidString)")
    }
    
    private func encodeMessage(_ message: ChatMessage) throws -> Data {
        // 使用简单的 JSON 编码
        let encoder = JSONEncoder()
        return try encoder.encode(MessageCacheData(from: message))
    }
    
    private func decodeMessage(_ data: Data) throws -> ChatMessage {
        let decoder = JSONDecoder()
        let cacheData = try decoder.decode(MessageCacheData.self, from: data)
        return cacheData.toDomain()
    }
    
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
}

// MARK: - 缓存数据结构

private struct MessageCacheData: Codable {
    let id: String
    let fromUserID: String
    let toUserID: String
    let content: Data
    let timestamp: TimeInterval
    
    init(from message: ChatMessage) {
        self.id = message.id
        self.fromUserID = message.fromUserID.uuidString
        self.toUserID = message.toUserID.uuidString
        self.content = message.content
        self.timestamp = message.timestamp.timeIntervalSince1970
    }
    
    func toDomain() -> ChatMessage {
        ChatMessage(
            id: id,
            fromUserID: UUID(uuidString: fromUserID) ?? UUID(),
            toUserID: UUID(uuidString: toUserID) ?? UUID(),
            content: content,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
    }
}

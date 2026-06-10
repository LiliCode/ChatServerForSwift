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
    
    public func cacheOfflineMessage(for userID: UUID, messageData: Data) async throws {
        let key = offlineMessageKey(for: userID)
        _ = try await redis.rpush(messageData, into: key).get()
    }
    
    public func fetchOfflineMessages(for userID: UUID) async throws -> [Data] {
        let key = offlineMessageKey(for: userID)
        
        // 获取所有消息
        let messages: [RESPValue] = try await redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        
        // 提取二进制数据
        var result: [Data] = []
        for value in messages {
            if let data = extractData(from: value) {
                result.append(data)
            }
        }
        
        return result
    }
    
    public func removeConfirmedMessage(userID: UUID, messageID: String) async throws {
        let key = offlineMessageKey(for: userID)
        
        let messages: [RESPValue] = try await redis.lrange(from: key, firstIndex: 0, lastIndex: -1).get()
        
        for (index, value) in messages.enumerated() {
            guard let data = extractData(from: value),
                  let pushMessage = try? PushMessage(serializedBytes: data),
                  pushMessage.hash == messageID else {
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

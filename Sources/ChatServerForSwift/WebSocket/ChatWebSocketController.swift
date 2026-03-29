import Vapor
import Fluent
import Foundation
import NIOWebSocket

/// 聊天 WebSocket 控制器
struct ChatWebSocketController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        routes.webSocket("chat", onUpgrade: handleWebSocket)
    }
    
    /// 处理 WebSocket 连接
    func handleWebSocket(req: Request, ws: WebSocket) async {
        // 从查询参数获取用户ID
        guard let userIDString = req.query[String.self, at: "userId"],
              let userID = UUID(uuidString: userIDString) else {
            await ws.closeWithReason(code: .policyViolation, reason: "缺少或无效的用户ID")
            return
        }
        
        // 验证用户是否存在
        guard let user = try? await User.find(userID, on: req.db) else {
            await ws.closeWithReason(code: .policyViolation, reason: "用户不存在")
            return
        }
        
        req.logger.info("用户 \(user.username) (\(userID)) 连接到 WebSocket")
        
        // 添加到连接管理器
        await ChatWebSocketManager.shared.addConnection(userID: userID, socket: ws)
        
        // 推送离线消息
        do {
            try await ChatWebSocketManager.shared.pushOfflineMessages(to: userID, on: req)
        } catch {
            req.logger.error("推送离线消息失败: \(error)")
        }
        
        // 处理消息
        ws.onBinary { ws, data in
            await handleBinaryMessage(ws: ws, data: data, userID: userID, req: req)
        }
        
        // 处理关闭
        ws.onClose.whenComplete { _ in
            Task {
                await ChatWebSocketManager.shared.removeConnection(userID: userID)
                req.logger.info("用户 \(user.username) (\(userID)) 断开 WebSocket 连接")
            }
        }
    }
    
    /// 处理二进制消息
    private func handleBinaryMessage(ws: WebSocket, data: ByteBuffer, userID: UUID, req: Request) async {
        guard let bytes = data.getBytes(at: 0, length: data.readableBytes) else {
            req.logger.warning("收到无效的二进制数据")
            return
        }
        
        let messageData = Data(bytes)
        
        do {
            // 解析消息
            let pushMessage = try PushMessage(serializedBytes: messageData)
            
            // 根据命令处理
            switch pushMessage.cmd {
            case .chatSendMessage:
                try await handleChatMessage(pushMessage: pushMessage, fromUserID: userID, req: req)
                
            case .receipt:
                try await handleReceipt(pushMessage: pushMessage, userID: userID, req: req)
                
            default:
                req.logger.warning("收到未知的命令类型: \(pushMessage.cmd)")
            }
            
        } catch {
            req.logger.error("处理消息失败: \(error)")
        }
    }
    
    /// 处理聊天消息
    private func handleChatMessage(pushMessage: PushMessage, fromUserID: UUID, req: Request) async throws {
        // 将 Int64 转换为 UUID 字符串
        let toUserIDString = String(pushMessage.to)
        guard let toUserID = UUID(uuidString: toUserIDString) else {
            req.logger.warning("无效的接收者ID: \(pushMessage.to)")
            return
        }
        
        // 验证接收者是否存在
        guard (try? await User.find(toUserID, on: req.db)) != nil else {
            req.logger.warning("接收者不存在: \(toUserID)")
            return
        }
        
        // 构建转发消息
        var forwardMessage = pushMessage
        // 将 UUID 转换为 Int64（取前8字节）
        let fromIDValue = uuidToInt64(fromUserID)
        forwardMessage.from = fromIDValue
        forwardMessage.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        // 发送给接收者
        try await ChatWebSocketManager.shared.sendMessage(
            to: toUserID,
            message: forwardMessage,
            on: req
        )
        
        req.logger.info("消息从 \(fromUserID) 转发到 \(toUserID), msgId: \(pushMessage.hash)")
    }
    
    /// 处理消息回执
    private func handleReceipt(pushMessage: PushMessage, userID: UUID, req: Request) async throws {
        // 从 payload 中解析回执信息
        // 回执消息包含已确认的消息 hash
        let messageHash = pushMessage.hash
        
        // 删除对应的离线消息
        try await ChatWebSocketManager.shared.removeConfirmedMessage(
            userID: userID,
            messageHash: messageHash,
            on: req
        )
        
        req.logger.info("用户 \(userID) 确认收到消息: \(messageHash)")
    }
}

// MARK: - 扩展

extension WebSocket {
    /// 异步关闭并发送原因
    func closeWithReason(code: WebSocketErrorCode, reason: String) async {
        // 先发送关闭原因文本消息，再关闭连接
        try? await send(reason)
        try? await close(code: code)
    }
}

/// 将 UUID 转换为 Int64
/// 取 UUID 的前 8 字节转换为 Int64
func uuidToInt64(_ uuid: UUID) -> Int64 {
    let uuidBytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
    let first8Bytes = Array(uuidBytes[0..<8])
    return first8Bytes.withUnsafeBytes { bytes in
        bytes.load(as: Int64.self)
    }
}

/// 将 Int64 转换为 UUID
/// 将 Int64 作为前 8 字节，后 8 字节补 0
func int64ToUUID(_ value: Int64) -> UUID? {
    var bytes = withUnsafeBytes(of: value) { Array($0) }
    // 补齐 16 字节
    bytes.append(contentsOf: [UInt8](repeating: 0, count: 8))
    return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                       bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
}

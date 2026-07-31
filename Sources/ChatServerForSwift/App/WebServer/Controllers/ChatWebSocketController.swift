import Vapor
import NIOWebSocket
import Foundation

/// WebSocket 聊天控制器
struct ChatWebSocketController: RouteCollection {
    private let sendMessage: SendMessage
    private let processReceipt: ProcessReceipt
    private let connectionManager: WebSocketConnectionManager
    private let tokenRepository: any TokenRepository
    
    init(
        sendMessage: SendMessage,
        processReceipt: ProcessReceipt,
        connectionManager: WebSocketConnectionManager,
        tokenRepository: any TokenRepository
    ) {
        self.sendMessage = sendMessage
        self.processReceipt = processReceipt
        self.connectionManager = connectionManager
        self.tokenRepository = tokenRepository
    }
    
    func boot(routes: any RoutesBuilder) throws {
        routes.webSocket("chat", onUpgrade: handleWebSocket)
    }
    
    /// 处理 WebSocket 连接
    func handleWebSocket(req: Request, ws: WebSocket) async {
        // 从查询参数获取会话令牌
        guard let token = req.query[String.self, at: "token"],
              let userID = try? await tokenRepository.findUserID(for: token) else {
            await ws.closeWithReason(code: .policyViolation, reason: "缺少或无效的令牌")
            return
        }
        
        req.logger.info("用户 \(userID) 连接到 WebSocket")
        
        // 添加到连接管理器
        await connectionManager.addConnection(userID: userID, socket: ws)
        
        // 推送离线消息
        do {
            try await connectionManager.pushOfflineMessages(to: userID)
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
                await connectionManager.removeConnection(userID: userID)
                req.logger.info("用户 \(userID) 断开 WebSocket 连接")
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
        // 将 Int64 转换回 UUID
        guard let toUserID = int64ToUUID(pushMessage.to) else {
            req.logger.warning("无效的接收者ID: \(pushMessage.to)")
            return
        }
        
        // 构建输入
        let input = SendMessageInput(
            fromUserID: fromUserID,
            toUserID: toUserID,
            content: pushMessage.payload,
            messageID: pushMessage.hash
        )
        
        // 执行发送消息用例
        try await sendMessage.execute(input)
        
        req.logger.info("消息从 \(fromUserID) 转发到 \(toUserID), msgId: \(pushMessage.hash)")
    }
    
    /// 处理消息回执
    private func handleReceipt(pushMessage: PushMessage, userID: UUID, req: Request) async throws {
        let input = MessageReceiptInput(
            userID: userID,
            messageID: pushMessage.hash
        )
        
        try await processReceipt.execute(input)
        
        req.logger.info("用户 \(userID) 确认收到消息: \(pushMessage.hash)")
    }
}

// MARK: - WebSocket 扩展

extension WebSocket {
    /// 异步关闭并发送原因
    func closeWithReason(code: WebSocketErrorCode, reason: String) async {
        try? await send(reason)
        try? await close(code: code)
    }
}

// MARK: - UUID 转换工具

func uuidToInt64(_ uuid: UUID) -> Int64 {
    let uuidBytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
    let first8Bytes = Array(uuidBytes[0..<8])
    return first8Bytes.withUnsafeBytes { bytes in
        bytes.load(as: Int64.self)
    }
}

func int64ToUUID(_ value: Int64) -> UUID? {
    var bytes = withUnsafeBytes(of: value) { Array($0) }
    bytes.append(contentsOf: [UInt8](repeating: 0, count: 8))
    return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                       bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
}

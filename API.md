# ChatServer API 文档

## 概述

本文档描述了 ChatServer 的 HTTP REST API 和 WebSocket 实时通信接口。

### 服务器地址

- **开发环境**: `http://localhost:8080`
- **WebSocket**: `ws://localhost:8080/chat`

### 协议说明

- HTTP API 使用 JSON 格式进行数据传输
- WebSocket 使用二进制 Protobuf 格式进行消息传输
- 所有时间戳使用 Unix 时间戳（毫秒）

### 认证方式

需要认证的接口需要在请求头中添加 `X-User-ID` 字段，值为用户的 UUID：

```
X-User-ID: 550e8400-e29b-41d4-a716-446655440000
```

---

## HTTP API

### 健康检查

#### GET /

检查服务器是否运行。

**响应**: `text/plain`
```
Chat Server is running!
```

#### GET /health

健康检查端点。

**响应**: `text/plain`
```
OK
```

---

### 用户接口

所有用户接口的基础路径为 `/api/v1`。

#### POST /api/v1/register

用户注册。

**请求头**:
```
Content-Type: application/json
```

**请求体**:
```json
{
  "username": "string",        // 用户名，必填
  "password": "string",        // 密码，必填
  "organizationCode": "string" // 组织代码，必填（如：ORG001）
}
```

**响应** (`200 OK`):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "nickname": "john_doe",
  "organizationCode": "ORG001",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**错误响应**:
- `400 Bad Request`: 请求参数无效
- `409 Conflict`: 用户名已存在

---

#### POST /api/v1/login

用户登录。

**请求头**:
```
Content-Type: application/json
```

**请求体**:
```json
{
  "username": "string",  // 用户名，必填
  "password": "string"   // 密码，必填
}
```

**响应** (`200 OK`):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "nickname": "John",
  "organizationCode": "ORG001",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**响应头**:
```
X-User-ID: 550e8400-e29b-41d4-a716-446655440000
```

**错误响应**:
- `400 Bad Request`: 请求参数无效
- `401 Unauthorized`: 用户名或密码错误

---

#### GET /api/v1/profile

获取当前用户信息（需要认证）。

**请求头**:
```
X-User-ID: {user_uuid}
```

**响应** (`200 OK`):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "nickname": "John",
  "organizationCode": "ORG001",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**错误响应**:
- `401 Unauthorized`: 未登录或登录已过期

---

#### POST /api/v1/password

修改密码（需要认证）。

**请求头**:
```
Content-Type: application/json
X-User-ID: {user_uuid}
```

**请求体**:
```json
{
  "oldPassword": "string",  // 旧密码，必填
  "newPassword": "string"   // 新密码，必填
}
```

**响应** (`200 OK`):
```
密码修改成功
```

**错误响应**:
- `400 Bad Request`: 请求参数无效
- `401 Unauthorized`: 未登录或旧密码错误

---

#### POST /api/v1/nickname

修改昵称（需要认证）。

**请求头**:
```
Content-Type: application/json
X-User-ID: {user_uuid}
```

**请求体**:
```json
{
  "nickname": "string"  // 新昵称，必填
}
```

**响应** (`200 OK`):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "john_doe",
  "nickname": "NewNickname",
  "organizationCode": "ORG001",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**错误响应**:
- `400 Bad Request`: 请求参数无效
- `401 Unauthorized`: 未登录

---

## WebSocket API

### 连接

**URL**: `ws://{host}/chat?userId={userId}`

**查询参数**:
- `userId` (必填): 用户 UUID，例如 `550e8400-e29b-41d4-a716-446655440000`

**连接流程**:
1. 客户端通过 HTTP 登录获取用户 ID
2. 使用用户 ID 建立 WebSocket 连接
3. 连接成功后，服务器会自动推送离线消息
4. 客户端可以发送和接收消息

### 消息格式

WebSocket 使用 **Protobuf** 二进制格式传输消息。

#### PushMessage 结构

```protobuf
syntax = "proto3";

message PushMessage {
  int64 from = 1;       // 发送者ID (Int64 格式的 UUID)
  int64 to = 2;         // 接收者ID (Int64 格式的 UUID)
  int64 timestamp = 3;  // 时间戳（毫秒）
  Command cmd = 4;      // 操作指令
  string hash = 5;      // 消息唯一标识（UUID 字符串）
  bytes payload = 6;    // 消息体的二进制数据（UTF-8 编码的字符串）
}

enum Command {
  chatSendMessage = 0;      // 发送普通消息
  receipt = 1;              // 消息回执
  twoWayDeletion = 2;       // 双向删除消息
  twoWayConversation = 3;   // 双向删除会话
}
```

### 命令说明

| 命令 | 值 | 说明 | 方向 |
|------|-----|------|------|
| `chatSendMessage` | 0 | 发送普通消息 | 客户端 → 服务器 → 接收者 |
| `receipt` | 1 | 消息回执（确认收到） | 客户端 → 服务器 |
| `twoWayDeletion` | 2 | 双向删除消息 | 客户端 → 服务器 → 双方 |
| `twoWayConversation` | 3 | 双向删除会话 | 客户端 → 服务器 → 双方 |

### 通信流程

#### 发送消息

1. 客户端构建 `PushMessage`：
   - `from`: 发送者 ID (Int64)
   - `to`: 接收者 ID (Int64)
   - `timestamp`: 当前时间戳
   - `cmd`: `chatSendMessage` (0)
   - `hash`: 消息唯一标识（UUID）
   - `payload`: 消息内容（UTF-8 编码）

2. 序列化为 Protobuf 二进制数据并发送

3. 服务器转发给接收者（如果在线）或存入离线缓存

#### 接收消息

1. 客户端监听 WebSocket 二进制消息

2. 解析 `PushMessage`：
   - `from`: 发送者 ID
   - `payload`: 消息内容

3. 发送回执确认收到：
   - `cmd`: `receipt` (1)
   - `hash`: 收到消息的 hash

#### 发送回执

```protobuf
PushMessage {
  from: {当前用户ID}
  to: {发送者ID}
  cmd: receipt (1)
  hash: {收到消息的hash}
}
```

---

## 示例代码

### Dart 示例 (使用 shelf_web_socket)

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:protobuf/protobuf.dart';

// 生成的 Protobuf 类（假设使用 protobuf 包）
// 实际使用时需要根据 .proto 文件生成

/// 聊天客户端示例
class ChatClient {
  final String baseUrl;
  final String wsUrl;
  String? userId;
  String? username;
  WebSocketChannel? _wsChannel;
  final _messageController = StreamController<PushMessage>.broadcast();

  ChatClient({
    this.baseUrl = 'http://localhost:8080',
    this.wsUrl = 'ws://localhost:8080',
  });

  /// 用户注册
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String organizationCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'organizationCode': organizationCode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      this.username = data['username'];
      return data;
    } else {
      throw Exception('注册失败: ${response.body}');
    }
  }

  /// 用户登录
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      userId = data['id'];
      this.username = data['username'];
      return data;
    } else {
      throw Exception('登录失败: ${response.body}');
    }
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> getProfile() async {
    if (userId == null) throw Exception('未登录');

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/profile'),
      headers: {'X-User-ID': userId!},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('获取用户信息失败: ${response.body}');
    }
  }

  /// 修改密码
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (userId == null) throw Exception('未登录');

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/password'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-ID': userId!,
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('修改密码失败: ${response.body}');
    }
  }

  /// 修改昵称
  Future<Map<String, dynamic>> changeNickname(String nickname) async {
    if (userId == null) throw Exception('未登录');

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/nickname'),
      headers: {
        'Content-Type': 'application/json',
        'X-User-ID': userId!,
      },
      body: jsonEncode({'nickname': nickname}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('修改昵称失败: ${response.body}');
    }
  }

  /// 连接 WebSocket
  Future<void> connectWebSocket() async {
    if (userId == null) throw Exception('未登录');

    final wsUri = Uri.parse('$wsUrl/chat?userId=$userId');
    _wsChannel = WebSocketChannel.connect(wsUri);

    _wsChannel!.stream.listen(
      (data) {
        if (data is List<int>) {
          _handleBinaryMessage(Uint8List.fromList(data));
        }
      },
      onError: (error) {
        print('WebSocket 错误: $error');
      },
      onDone: () {
        print('WebSocket 连接关闭');
      },
    );

    print('WebSocket 已连接');
  }

  /// 处理二进制消息
  void _handleBinaryMessage(Uint8List data) {
    try {
      // 使用 protobuf 解析 PushMessage
      final message = PushMessage.fromBuffer(data);
      _messageController.add(message);

      // 自动发送回执
      if (message.cmd == Command.chatSendMessage) {
        sendReceipt(message.hash);
      }
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  /// 发送消息
  void sendMessage({
    required String toUserId,
    required String content,
  }) {
    if (_wsChannel == null) throw Exception('WebSocket 未连接');

    final message = PushMessage(
      from: uuidToInt64(userId!),
      to: uuidToInt64(toUserId),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      cmd: Command.chatSendMessage,
      hash: generateUuid(),
      payload: utf8.encode(content),
    );

    _wsChannel!.sink.add(message.writeToBuffer());
  }

  /// 发送回执
  void sendReceipt(String messageHash) {
    if (_wsChannel == null) return;

    final receipt = PushMessage(
      from: uuidToInt64(userId!),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      cmd: Command.receipt,
      hash: messageHash,
    );

    _wsChannel!.sink.add(receipt.writeToBuffer());
  }

  /// 断开 WebSocket 连接
  void disconnect() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  /// 消息流
  Stream<PushMessage> get messageStream => _messageController.stream;
}

/// 辅助函数：UUID 转 Int64
int uuidToInt64(String uuid) {
  // 实现 UUID 到 Int64 的转换
  // 取 UUID 前 8 个字节转换为 Int64
  final bytes = uuidToBytes(uuid);
  final buffer = ByteData.sublistView(Uint8List.fromList(bytes.sublist(0, 8)));
  return buffer.getInt64(0, Endian.big);
}

/// 辅助函数：UUID 字符串转字节
List<int> uuidToBytes(String uuid) {
  final cleanUuid = uuid.replaceAll('-', '');
  final bytes = <int>[];
  for (var i = 0; i < cleanUuid.length; i += 2) {
    bytes.add(int.parse(cleanUuid.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

/// 辅助函数：生成 UUID
String generateUuid() {
  return '${_randomHex(8)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(4)}-${_randomHex(12)}';
}

String _randomHex(int length) {
  final random = Random.secure();
  final chars = '0123456789abcdef';
  return List.generate(length, (_) => chars[random.nextInt(16)]).join();
}

// ==================== 使用示例 ====================

void main() async {
  final client = ChatClient();

  try {
    // 1. 登录
    print('正在登录...');
    final loginResult = await client.login(
      username: 'john_doe',
      password: 'password123',
    );
    print('登录成功: ${loginResult['nickname']}');

    // 2. 连接 WebSocket
    print('连接 WebSocket...');
    await client.connectWebSocket();

    // 3. 监听消息
    client.messageStream.listen((message) {
      final content = utf8.decode(message.payload);
      print('收到消息 [${message.hash}]: $content');
    });

    // 4. 发送消息
    print('发送消息...');
    client.sendMessage(
      toUserId: '接收者UUID',
      content: '你好，这是一条测试消息！',
    );

    // 5. 获取用户信息
    final profile = await client.getProfile();
    print('用户信息: ${profile['nickname']}');

    // 6. 修改昵称
    await client.changeNickname('新昵称');
    print('昵称修改成功');

    // 保持连接
    await Future.delayed(Duration(minutes: 5));
  } catch (e) {
    print('错误: $e');
  } finally {
    client.disconnect();
  }
}
```

#### pubspec.yaml 依赖

```yaml
dependencies:
  http: ^1.1.0
  shelf: ^1.4.1
  shelf_web_socket: ^2.0.0
  web_socket_channel: ^2.4.0
  protobuf: ^3.1.0
```

---

### Swift 示例

```swift
import Foundation

// MARK: - HTTP API 客户端

class ChatAPIClient {
    private let baseURL: URL
    private var userId: String?
    
    init(baseURL: String = "http://localhost:8080") {
        self.baseURL = URL(string: baseURL)!
    }
    
    // MARK: - 健康检查
    
    func healthCheck() async throws -> String {
        let url = baseURL.appendingPathComponent("health")
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    // MARK: - 用户注册
    
    func register(username: String, password: String, organizationCode: String) async throws -> UserResponse {
        let url = baseURL.appendingPathComponent("api/v1/register")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RegisterRequest(
            username: username,
            password: password,
            organizationCode: organizationCode
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }
    
    // MARK: - 用户登录
    
    func login(username: String, password: String) async throws -> UserResponse {
        let url = baseURL.appendingPathComponent("api/v1/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(username: username, password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        self.userId = userResponse.id
        return userResponse
    }
    
    // MARK: - 获取用户信息
    
    func getProfile() async throws -> UserResponse {
        guard let userId = userId else {
            throw APIError.notAuthenticated
        }
        
        let url = baseURL.appendingPathComponent("api/v1/profile")
        var request = URLRequest(url: url)
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }
    
    // MARK: - 修改密码
    
    func changePassword(oldPassword: String, newPassword: String) async throws {
        guard let userId = userId else {
            throw APIError.notAuthenticated
        }
        
        let url = baseURL.appendingPathComponent("api/v1/password")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body = ChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed("Change password failed")
        }
    }
    
    // MARK: - 修改昵称
    
    func changeNickname(nickname: String) async throws -> UserResponse {
        guard let userId = userId else {
            throw APIError.notAuthenticated
        }
        
        let url = baseURL.appendingPathComponent("api/v1/nickname")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let body = ChangeNicknameRequest(nickname: nickname)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }
}

// MARK: - WebSocket 客户端

class ChatWebSocketClient: NSObject {
    private var webSocketTask: URLSessionWebSocketTask?
    private let baseURL: String
    private var userId: String
    
    var onMessageReceived: ((PushMessage) -> Void)?
    var onConnected: (() -> Void)?
    var onDisconnected: ((Error?) -> Void)?
    
    init(baseURL: String = "ws://localhost:8080", userId: String) {
        self.baseURL = baseURL
        self.userId = userId
        super.init()
    }
    
    // MARK: - 连接
    
    func connect() {
        let urlString = "\(baseURL)/chat?userId=\(userId)"
        guard let url = URL(string: urlString) else {
            onDisconnected?(APIError.invalidURL)
            return
        }
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.delegate = self
        
        webSocketTask?.resume()
        receiveMessage()
    }
    
    // MARK: - 断开连接
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }
    
    // MARK: - 发送消息
    
    func sendMessage(toUserId: String, content: String) {
        let message = PushMessage(
            from: uuidToInt64(userId),
            to: uuidToInt64(toUserId),
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            cmd: .chatSendMessage,
            hash: UUID().uuidString,
            payload: content.data(using: .utf8) ?? Data()
        )
        
        do {
            let data = try message.serializedData()
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("发送消息失败: \(error)")
                }
            }
        } catch {
            print("序列化消息失败: \(error)")
        }
    }
    
    // MARK: - 发送回执
    
    func sendReceipt(messageHash: String) {
        let receipt = PushMessage(
            from: uuidToInt64(userId),
            to: 0,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000),
            cmd: .receipt,
            hash: messageHash,
            payload: Data()
        )
        
        do {
            let data = try receipt.serializedData()
            webSocketTask?.send(.data(data)) { error in
                if let error = error {
                    print("发送回执失败: \(error)")
                }
            }
        } catch {
            print("序列化回执失败: \(error)")
        }
    }
    
    // MARK: - 接收消息
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.handleBinaryMessage(data)
                case .string(let text):
                    print("收到文本消息: \(text)")
                @unknown default:
                    break
                }
                // 继续接收下一条消息
                self?.receiveMessage()
                
            case .failure(let error):
                print("接收消息失败: \(error)")
                self?.onDisconnected?(error)
            }
        }
    }
    
    private func handleBinaryMessage(_ data: Data) {
        do {
            let message = try PushMessage(serializedBytes: data)
            onMessageReceived?(message)
            
            // 自动发送回执
            if message.cmd == .chatSendMessage {
                sendReceipt(messageHash: message.hash)
            }
        } catch {
            print("解析消息失败: \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate

extension ChatWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket 已连接")
        onConnected?()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("WebSocket 连接错误: \(error)")
            onDisconnected?(error)
        }
    }
}

// MARK: - 数据模型

struct RegisterRequest: Codable {
    let username: String
    let password: String
    let organizationCode: String
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct ChangePasswordRequest: Codable {
    let oldPassword: String
    let newPassword: String
}

struct ChangeNicknameRequest: Codable {
    let nickname: String
}

struct UserResponse: Codable {
    let id: String
    let username: String
    let nickname: String
    let organizationCode: String
    let createdAt: Date?
}

enum APIError: Error {
    case notAuthenticated
    case invalidURL
    case requestFailed(String)
}

// MARK: - Protobuf 消息定义（简化版）

// 注意：实际使用时需要使用 swift-protobuf 生成的代码
// 这里展示的是简化的结构定义

enum Command: Int {
    case chatSendMessage = 0
    case receipt = 1
    case twoWayDeletion = 2
    case twoWayConversation = 3
}

struct PushMessage {
    var from: Int64 = 0
    var to: Int64 = 0
    var timestamp: Int64 = 0
    var cmd: Command = .chatSendMessage
    var hash: String = ""
    var payload: Data = Data()
    
    func serializedData() throws -> Data {
        // 实际实现使用 swift-protobuf
        // 这里简化处理
        var data = Data()
        // 序列化逻辑...
        return data
    }
    
    init(serializedBytes: Data) throws {
        // 实际实现使用 swift-protobuf
        // 这里简化处理
        self.init()
    }
    
    init() {}
    
    init(from: Int64, to: Int64, timestamp: Int64, cmd: Command, hash: String, payload: Data) {
        self.from = from
        self.to = to
        self.timestamp = timestamp
        self.cmd = cmd
        self.hash = hash
        self.payload = payload
    }
}

// MARK: - UUID 转换工具

func uuidToInt64(_ uuidString: String) -> Int64 {
    guard let uuid = UUID(uuidString: uuidString) else { return 0 }
    let uuidBytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }
    let first8Bytes = Array(uuidBytes[0..<8])
    return first8Bytes.withUnsafeBytes { bytes in
        bytes.load(as: Int64.self)
    }
}

// MARK: - 使用示例

class ChatExample {
    private var apiClient: ChatAPIClient!
    private var wsClient: ChatWebSocketClient?
    
    func run() async {
        apiClient = ChatAPIClient()
        
        do {
            // 1. 登录
            print("正在登录...")
            let user = try await apiClient.login(username: "john_doe", password: "password123")
            print("登录成功: \(user.nickname)")
            
            // 2. 连接 WebSocket
            print("连接 WebSocket...")
            wsClient = ChatWebSocketClient(userId: user.id)
            setupWebSocketHandlers()
            wsClient?.connect()
            
            // 3. 发送消息
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.wsClient?.sendMessage(
                    toUserId: "接收者UUID",
                    content: "你好，这是一条测试消息！"
                )
            }
            
            // 4. 获取用户信息
            let profile = try await apiClient.getProfile()
            print("用户信息: \(profile.nickname)")
            
            // 5. 修改昵称
            let updated = try await apiClient.changeNickname(nickname: "新昵称")
            print("昵称修改成功: \(updated.nickname)")
            
        } catch {
            print("错误: \(error)")
        }
    }
    
    private func setupWebSocketHandlers() {
        wsClient?.onConnected = {
            print("WebSocket 连接成功")
        }
        
        wsClient?.onMessageReceived = { message in
            if let content = String(data: message.payload, encoding: .utf8) {
                print("收到消息 [\(message.hash)]: \(content)")
            }
        }
        
        wsClient?.onDisconnected = { error in
            print("WebSocket 断开: \(String(describing: error))")
        }
    }
}

// 运行示例
// Task { await ChatExample().run() }
```

---

## 错误码

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 400 | 请求参数错误 |
| 401 | 未认证或认证失败 |
| 404 | 资源不存在 |
| 409 | 资源冲突（如用户名已存在） |
| 500 | 服务器内部错误 |

### WebSocket 关闭码

| 关闭码 | 说明 |
|--------|------|
| 1000 | 正常关闭 |
| 1006 | 异常关闭 |
| 1008 | 策略违规（如缺少 userId） |

---

## 注意事项

1. **UUID 转换**: WebSocket 消息中的用户 ID 使用 Int64 格式存储，需要通过特定算法将 UUID 字符串转换为 Int64。

2. **消息回执**: 客户端收到消息后应发送回执（receipt）确认，以便服务器更新消息状态。

3. **离线消息**: 用户重新连接 WebSocket 时，服务器会自动推送离线期间的消息。

4. **Protobuf**: 实际开发时需要根据 `PushMessage.proto` 文件生成对应语言的代码：
   - Dart: `protoc --dart_out=. PushMessage.proto`
   - Swift: `protoc --swift_out=. PushMessage.proto`

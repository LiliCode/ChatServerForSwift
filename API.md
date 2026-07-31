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

**当前实现**：登录接口成功后，响应头 `X-User-ID` 返回当前用户 UUID。所有需要认证的接口都通过请求头携带 `X-User-ID` 进行认证：

```
X-User-ID: 550e8400-e29b-41d4-a716-446655440000
```

需要认证的接口（`/api/v1/profile`、`/password`、`/nickname`、`/keys` 等）缺少或携带无效的 `X-User-ID` 时返回 `401 Unauthorized`。

> **⚠️ 安全限制**：当前认证仅凭 `X-User-ID` 请求头，**无 token、签名或有效期校验**。任何获取到他人 UUID 的客户端都可以冒充该用户。该机制仅适用于开发/内部环境，生产环境必须替换为更强的认证方案（如登录 token + 会话管理）。

**使用要点**：
1. 登录响应头中的 `X-User-ID` 即用户身份标识，客户端应保存并在后续所有请求中回传
2. WebSocket 连接使用同一 `userId`（通过 URL 查询参数 `userId` 传递）

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

**字段校验规则**:
- `username`: 3-20 个字符，仅允许字母、数字、下划线
- `password`: 至少 6 个字符
- `organizationCode`: 非空，且必须存在（默认组织：`ORG001`、`ORG002`、`ORG003`）

**错误响应**:
- `400 Bad Request`: 参数格式无效 / 组织不存在
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
- `400 Bad Request`: 请求参数无效
- `401 Unauthorized`: 未登录或登录已过期
- `404 Not Found`: 用户不存在

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
- `400 Bad Request`: 请求参数无效 / 旧密码错误 / 新密码格式错误
- `401 Unauthorized`: 未登录
- `404 Not Found`: 用户不存在

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
- `400 Bad Request`: 请求参数无效（昵称 1-20 个字符）
- `401 Unauthorized`: 未登录
- `404 Not Found`: 用户不存在

---

#### POST /api/v1/keys

上传当前用户的 E2EE 公钥（需要认证）。

**请求头**:
```
Content-Type: application/json
X-User-ID: {user_uuid}
```

**请求体**:
```json
{
  "publicKey": "base64编码的32字节X25519公钥"
}
```

**响应** (`200 OK`):
```
公钥上传成功
```

**错误响应**:
- `400 Bad Request`: 公钥格式无效（非 base64 或长度非 32 字节）
- `401 Unauthorized`: 未登录
- `404 Not Found`: 用户不存在

---

#### GET /api/v1/keys/{userID}

获取指定用户的 E2EE 公钥（需要认证）。

**请求头**:
```
X-User-ID: {user_uuid}
```

**响应** (`200 OK`):
```json
{
  "userID": "550e8400-e29b-41d4-a716-446655440000",
  "publicKey": "base64编码的32字节X25519公钥"
}
```

未设置公钥时 `publicKey` 为 `null`。

**错误响应**:
- `400 Bad Request`: userID 无效
- `401 Unauthorized`: 未登录

---

## 端到端加密（E2EE）与助记词恢复

### 概述

消息内容使用 X25519 + AES-GCM 端到端加密，服务器仅保存用户公钥，**永远无法解密消息内容**。加密与解密完全在客户端完成，服务器对 `PushMessage.payload` 中的密文透明转发/缓存。

### 密钥体系

| 项目 | 说明 |
|------|------|
| 算法 | X25519 曲线（公钥 32 字节） |
| 助记词 | 标准 BIP39 英文（12 词，128 bit 熵） |
| 私钥派生 | 助记词 → PBKDF2 → seed → HKDF → X25519 私钥 |
| 私钥存储 | **仅存客户端本地**（Keychain），服务器不保存 |
| 公钥存储 | 服务器（`POST /api/v1/keys` 上传，`GET /api/v1/keys/{id}` 获取） |

### 助记词 → 私钥派生算法（客户端实现规范）

```
① 生成 128 bit 安全随机熵
② BIP39 校验和：取熵的 SHA-256 前 4 bit 附加到末尾（共 132 bit）
③ 每 11 bit 映射一个 BIP39 单词表下标 → 得到 12 个英文助记词
④ seed = PBKDF2-HMAC-SHA512(
       password = 助记词短语（单词间空格分隔）,
       salt = "mnemonic"（BIP39 固定值，可附加可选口令）,
       iterations = 2048
   )                      → 64 字节 seed
⑤ 私钥 = HKDF-SHA256(
       inputKey = seed,
       salt = "chat-e2ee",
       info = "x25519-private-key"
   )                      → 32 字节
⑥ X25519 私钥 clamp 后派生公钥
```

### 恢复流程（App 删除 / 换新设备）

1. 用户输入 12 个助记词
2. 客户端按上述算法**确定性**派生同一私钥（同一助记词 → 同一私钥）
3. 从私钥派生公钥
4. `POST /api/v1/keys` 重新上传公钥（服务端只存公钥，不存私钥）
5. 历史消息全部可解密，账号无需重建

### 消息加解密（客户端实现规范）

```
发送：key = X25519协商(A私钥, B公钥)
      ciphertext = AES-256-GCM(key, 明文)
      PushMessage.payload = ciphertext + 随机盐

接收：key = X25519协商(B私钥, A公钥)
      明文 = AES-256-GCM(key, ciphertext)
```

服务器对 `payload` 内容无感知，仅作为不透明二进制转发与缓存。

---

## WebSocket API

### 连接

**URL**: `ws://{host}/chat?userId={userId}`

**查询参数**:
- `userId` (必填): 用户 UUID，例如 `550e8400-e29b-41d4-a716-446655440000`

**连接流程**:
1. 客户端通过 HTTP 登录获取用户 ID
2. 使用用户 ID 建立 WebSocket 连接
3. 连接成功后，服务器自动推送该用户的**全部离线消息**（Redis 中尚未收到回执的消息）
4. 客户端对收到的每条消息发送回执后，消息才从服务器删除
5. 客户端可以继续发送和接收消息

> **多设备/重复连接注意**：同一用户重复连接 WebSocket 时，会再次收到所有尚未发送回执的消息。客户端应根据消息 `hash` 做去重。已发送回执的消息不会被再次推送。

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
  bytes payload = 6;    // 消息体的二进制数据（UTF-8 编码的字符串或 E2EE 密文）
}

enum Command {
  chatSendMessage = 0;      // 发送普通消息
  receipt = 1;              // 消息回执
  twoWayDeletion = 2;       // 双向删除消息（预留未实现）
  twoWayConversation = 3;   // 双向删除会话（预留未实现）
}
```

**字段注意**：
- `from`/`to` 使用 `uuidToInt64` 算法转换（见下方「UUID 转换」），转换算法与服务器一致才能正确解析
- 服务器解析消息时**忽略 `from` 字段**，发送者身份以 WebSocket 连接时的 `userId` 参数为准
- 服务器收到 `chatSendMessage` 后会校验接收者 `to` 是否有效且存在，无效时仅记录日志，**客户端无任何反馈**

### 命令说明

| 命令 | 值 | 说明 | 方向 | 服务端状态 |
|------|-----|------|------|-----------|
| `chatSendMessage` | 0 | 发送普通消息 | 客户端 → 服务器 → 接收者 | ✅ 已实现 |
| `receipt` | 1 | 消息回执（确认收到） | 客户端 → 服务器 | ✅ 已实现 |
| `twoWayDeletion` | 2 | 双向删除消息 | 客户端 → 服务器 → 双方 | ⏳ 预留未实现 |
| `twoWayConversation` | 3 | 双向删除会话 | 客户端 → 服务器 → 双方 | ⏳ 预留未实现 |

> **注意**：`twoWayDeletion` 和 `twoWayConversation` 命令在服务端尚未实现，当前收到后仅记录日志忽略。客户端不应依赖这两个命令。

### 通信流程

#### 发送消息

1. 客户端构建 `PushMessage`：
   - `from`: 发送者 ID (Int64，**服务端会忽略，实际以连接时的 userId 为准**)
   - `to`: 接收者 ID (Int64，与 `from` 使用相同的 UUID→Int64 转换算法)
   - `timestamp`: 当前时间戳（毫秒）
   - `cmd`: `chatSendMessage` (0)
   - `hash`: 消息唯一标识（客户端生成 UUID）
   - `payload`: 消息内容（UTF-8 编码的明文或 E2EE 密文）

2. 序列化为 Protobuf 二进制数据并通过 WebSocket 发送

3. 服务端处理逻辑（**先缓存、后推送**）：
   - **始终**将消息写入接收者的 Redis 离线缓存（`offline:msg:{接收者UUID}`）
   - 接收者**在线** → 立即通过 WebSocket 推送给接收者
   - 接收者**离线** → 等待其上线时由服务器推送

4. 消息将**一直保留在 Redis 中，直到收到接收者的回执才删除**

> **重要**：服务端不会向发送者返回任何送达确认。发送方无法从服务端获知消息是否送达；送达状态需要接收方回复或业务层面确认。

#### 接收消息

1. 客户端监听 WebSocket 二进制消息

2. 解析 `PushMessage`：
   - `from`: 发送者 ID (Int64，需转换为 UUID)
   - `to`: 接收者 ID（即本用户 ID）
   - `hash`: 消息唯一标识
   - `payload`: 消息内容

3. **必须发送回执确认收到**，否则消息不会从服务器删除：
   - `cmd`: `receipt` (1)
   - `hash`: 收到消息的 hash

> **⚠️ 回执缺失的后果**：若客户端不发送回执，消息会永久保留在 Redis 中，用户**每次重新连接 WebSocket 都会重复收到**该消息。客户端应在成功解析并落盘/入库消息后立即发送回执，避免重复消费。

#### 发送回执

```protobuf
PushMessage {
  from: {当前用户ID}
  to: {发送者ID}
  cmd: receipt (1)
  hash: {收到消息的hash}
}
```

> **注意**：服务端处理回执时只使用 `hash` 字段和当前连接的 `userId`，`from`/`to` 字段被忽略。

---

## 完整对接流程

以下为客户端对接本服务的**推荐时序**，涵盖账号、E2EE、实时通信与离线恢复。

### 第 1 步：注册

```
POST /api/v1/register
{ "username", "password", "organizationCode" }
→ 200 { "id", "username", "nickname", "organizationCode", "createdAt" }
```

### 第 2 步：登录并保存身份

```
POST /api/v1/login
{ "username", "password" }
→ 200 { "id", ... }  （响应头 X-User-ID 即为用户 id）
```

- 保存响应头 `X-User-ID`（即用户 UUID），后续所有 HTTP 请求携带
- 登录接口响应体中的 `id` 与 `X-User-ID` 相同

### 第 3 步：E2EE 密钥设置（仅首次 / 换设备时）

1. 客户端生成 12 个 BIP39 英文助记词，**展示给用户备份**
2. 按「端到端加密」章节的派生算法生成 X25519 私钥/公钥，私钥存本地 Keychain
3. 上传公钥：`POST /api/v1/keys`，body `{ "publicKey": "<base64 公钥>" }`

> 若已在本设备设置过密钥（本地已有私钥），可跳过此步。App 删除重装后凭助记词恢复私钥并重新上传公钥。

### 第 4 步：连接 WebSocket

```
ws://{host}/chat?userId={用户UUID}
```

连接成功后，服务端会立即推送所有尚未收到回执的离线消息。

### 第 5 步：发消息前获取对方公钥（E2EE）

```
GET /api/v1/keys/{对方UUID}   （请求头带 X-User-ID）
→ 200 { "userID", "publicKey" }
```

- `publicKey` 为 `null` 表示对方未设置 E2EE 公钥（可能无法解密，需提示）
- 客户端应**缓存对方公钥**，仅在找不到或怀疑密钥变更时重新拉取

### 第 6 步：发送消息

1. 用对方公钥加密消息内容（见「消息加解密」）
2. 构建 `PushMessage`（`cmd=chatSendMessage`，`to=uuidToInt64(对方UUID)`，`hash=新UUID`，`payload=密文`）
3. 通过 WebSocket 二进制帧发送
4. 服务端缓存到 Redis 并转发（对方在线则立即送达，离线则等其上线）

### 第 7 步：接收消息并发送回执

1. 收到二进制帧 → 解析 `PushMessage`
2. 用本地私钥解密 `payload`（E2EE）
3. **落盘/入库成功后立即发送回执**：`cmd=receipt`，`hash=消息hash`
4. 服务端收到回执后删除 Redis 中该条消息

### 第 8 步：离线消息恢复

用户离线期间的消息在 Redis 中累积；再次连接 WebSocket 时服务端全部推送。客户端按 `hash` 去重（已消费过的不重复展示），并逐条发送回执。

### 时序图

```
客户端A                     服务端                        客户端B
  │ POST /register            │                              │
  │──────────────────────────▶│                              │
  │ POST /login               │                              │
  │──────────────────────────▶│                              │
  │◀──────────────────────────│  (X-User-ID 响应头)           │
  │ POST /keys (上传公钥)      │                              │
  │──────────────────────────▶│                              │
  │ WS /chat?userId=A         │                              │
  │══════════════════════════▶│                              │
  │                           │  (B离线，消息缓存Redis)       │
  │ GET /keys/B ─────────────▶│                              │
  │◀──────────────────────────│                              │
  │ WS 发送 PushMessage ─────▶│                              │
  │                           │  B上线 WS /chat?userId=B     │
  │                           │◀════════════════════════════│
  │                           │─── PushMessage 推送 ────────▶│
  │                           │◀── receipt ─────────────────│
  │                           │  (从 Redis 删除该消息)       │
```

---

## 示例代码

### Dart 示例 (使用 web_socket_channel + protobuf)

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:protobuf/protobuf.dart';

// 生成的 Protobuf 类（protoc --dart_out=. PushMessage.proto）
// 完整对接流程：注册 → 登录 → 上传公钥 → 连接 → 收发消息 → 回执 → 离线恢复

class ChatClient {
  final String baseUrl;
  final String wsUrl;
  String? userId;
  WebSocketChannel? _wsChannel;
  final _messageController = StreamController<PushMessage>.broadcast();

  ChatClient({
    this.baseUrl = 'http://localhost:8080',
    this.wsUrl = 'ws://localhost:8080',
  });

  Map<String, String> _authHeaders() => {
        'Content-Type': 'application/json',
        if (userId != null) 'X-User-ID': userId!,
      };

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
      return jsonDecode(response.body);
    }
    throw Exception('注册失败(${response.statusCode}): ${response.body}');
  }

  /// 用户登录（保存 userId，后续所有请求带 X-User-ID）
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      userId = data['id'];
      return data;
    }
    throw Exception('登录失败(${response.statusCode}): ${response.body}');
  }

  /// 上传 E2EE 公钥（base64）
  Future<void> uploadPublicKey(String base64PublicKey) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/keys'),
      headers: _authHeaders(),
      body: jsonEncode({'publicKey': base64PublicKey}),
    );
    if (response.statusCode != 200) {
      throw Exception('上传公钥失败(${response.statusCode}): ${response.body}');
    }
  }

  /// 获取对方公钥（未设置时返回 null）
  Future<String?> getPublicKey(String targetUserId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/keys/$targetUserId'),
      headers: _authHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['publicKey'] as String?;
    }
    throw Exception('获取公钥失败(${response.statusCode}): ${response.body}');
  }

  /// 连接 WebSocket，服务器会自动推送未回执的离线消息
  Future<void> connect() async {
    if (userId == null) throw Exception('未登录');
    final wsUri = Uri.parse('$wsUrl/chat?userId=$userId');
    _wsChannel = WebSocketChannel.connect(wsUri);
    _wsChannel!.stream.listen(
      (data) {
        if (data is List<int>) {
          _handleBinary(Uint8List.fromList(data));
        }
      },
      onError: (e) => print('WebSocket 错误: $e'),
      onDone: () => print('WebSocket 已关闭'),
    );
  }

  /// 处理二进制消息，落盘后立即发送回执
  void _handleBinary(Uint8List data) {
    try {
      final msg = PushMessage.fromBuffer(data);
      _messageController.add(msg);
      // E2EE：此处用本地私钥解密 msg.payload
      // final plaintext = e2eeDecrypt(msg.payload);
      // 落盘/入库成功后立即发送回执，否则服务端不删除缓存、重连会重复推送
      if (msg.cmd == Command.chatSendMessage) {
        _sendReceipt(msg.hash);
      }
    } catch (e) {
      print('解析消息失败: $e');
    }
  }

  /// 发送消息（发送前需获取并缓存对方公钥做 E2EE 加密）
  void sendMessage({
    required String toUserId,
    required String content,
  }) {
    if (_wsChannel == null) throw Exception('WebSocket 未连接');
    // E2EE：使用对方公钥加密内容后写入 payload
    // final encrypted = e2eeEncrypt(toUserId, utf8.encode(content));
    final msg = PushMessage(
      from: uuidToInt64(userId!),
      to: uuidToInt64(toUserId),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      cmd: Command.chatSendMessage,
      hash: generateUuid(),
      payload: utf8.encode(content),
    );
    _wsChannel!.sink.add(msg.writeToBuffer());
  }

  /// 发送回执（触发服务端删除 Redis 缓存）
  void _sendReceipt(String messageHash) {
    if (_wsChannel == null) return;
    final receipt = PushMessage(
      from: uuidToInt64(userId!),
      cmd: Command.receipt,
      hash: messageHash,
    );
    _wsChannel!.sink.add(receipt.writeToBuffer());
  }

  void disconnect() {
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  Stream<PushMessage> get messages => _messageController.stream;
}

/// UUID → Int64（与服务端一致的转换：取 UUID 前 8 字节按小端序解释）
int uuidToInt64(String uuid) {
  final clean = uuid.replaceAll('-', '');
  final bytes = <int>[
    for (var i = 0; i < clean.length; i += 2)
      int.parse(clean.substring(i, i + 2), radix: 16),
  ];
  final buffer = ByteData.sublistView(Uint8List.fromList(bytes.sublist(0, 8)));
  return buffer.getInt64(0, Endian.little);
}

/// 生成 UUID
String generateUuid() {
  final random = Random.secure();
  String hex(int len) =>
      List.generate(len, (_) => random.nextInt(16).toRadixString(16)).join();
  return '${hex(8)}-${hex(4)}-${hex(4)}-${hex(4)}-${hex(12)}';
}

/// E2EE 加解密说明（客户端实现）：
/// 发送：key = X25519(我方私钥, 对方公钥)
///       密文 = AES-256-GCM(key, 明文) → 写入 PushMessage.payload
/// 接收：key = X25519(我方私钥, 对方公钥)
///       明文 = AES-256-GCM(key, 密文)
/// 可用 package:cryptography 或 pointycastle 实现

// ==================== 使用示例 ====================

Future<void> main() async {
  final client = ChatClient();

  // 1. 登录
  await client.login(username: 'john_doe', password: 'password123');

  // 2. 上传公钥（首次使用：助记词 → X25519 密钥对 → 上传公钥）
  // await client.uploadPublicKey(base64Encode(publicKeyBytes));

  // 3. 连接 WebSocket（自动接收离线消息）
  await client.connect();

  // 4. 监听消息（自动回执）
  client.messages.listen((msg) {
    final content = utf8.decode(msg.payload); // E2EE 时需先解密
    print('收到消息 [${msg.hash}]: $content');
  });

  // 5. 发送消息（发送前获取对方公钥做 E2EE）
  // final peerKey = await client.getPublicKey('对方UUID');
  client.sendMessage(toUserId: '对方UUID', content: '你好！');

  await Future.delayed(const Duration(minutes: 5));
  client.disconnect();
}
```

#### pubspec.yaml 依赖

```yaml
dependencies:
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  protobuf: ^3.1.0
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
    
    // MARK: - 上传 E2EE 公钥
    
    func uploadPublicKey(_ publicKey: String) async throws {
        guard let userId = userId else {
            throw APIError.notAuthenticated
        }
        
        let url = baseURL.appendingPathComponent("api/v1/keys")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        struct Body: Encodable { let publicKey: String }
        request.httpBody = try JSONEncoder().encode(Body(publicKey: publicKey))
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed("Upload public key failed")
        }
    }
    
    // MARK: - 获取对方公钥（E2EE 发送前调用）
    
    func getPublicKey(of userID: String) async throws -> String? {
        guard let userId = userId else {
            throw APIError.notAuthenticated
        }
        
        let url = baseURL.appendingPathComponent("api/v1/keys/\(userID)")
        var request = URLRequest(url: url)
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(String(data: data, encoding: .utf8) ?? "Unknown error")
        }
        
        struct Response: Decodable { let userID: String; let publicKey: String? }
        return try JSONDecoder().decode(Response.self, from: data).publicKey
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
        // E2EE：发送前先用 `apiClient.getPublicKey(of: toUserId)` 获取对方公钥，
        // 并用 X25519 协商密钥 + AES-GCM 加密 content，将密文写入 payload。
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
            // E2EE：此处先用本地私钥解密 message.payload 后再展示
            onMessageReceived?(message)
            
            // 自动发送回执（落盘成功后必须发送，否则服务端不删除缓存、重连重复推送）
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

1. **UUID 转换**: WebSocket 消息中的用户 ID 使用 Int64 格式存储，需要通过 `uuidToInt64` 算法将 UUID 字符串转换为 Int64，且转换算法必须与服务器一致（取 UUID 前 8 字节按本机字节序解释为 Int64）。服务器解析接收者 ID 时会用逆转换还原 UUID。

2. **消息回执是必须的**: 客户端收到消息并成功处理（落盘/入库）后，**必须发送回执**（`cmd=receipt` + `hash`）。回执用于触发服务器从 Redis 删除该消息。不发送回执会导致消息永久驻留缓存、每次重连重复推送。

3. **离线消息**: 用户重新连接 WebSocket 时，服务器会自动推送 Redis 中所有尚未收到回执的离线消息；客户端应依据 `hash` 去重。

4. **发送无确认**: 服务器不会向发送方返回任何送达/失败确认。若接收者不存在或发送失败，仅记录在服务器日志中，发送方无感知。

5. **认证凭据**: 当前认证仅依赖 `X-User-ID` 请求头（WebSocket 用 `userId` 查询参数），无有效期与签名校验，泄露 UUID 即可冒充。生产环境需更换更强认证方案。

6. **E2EE 公钥**: 公钥上传后长期有效，可随时通过 `POST /api/v1/keys` 覆盖更新（如换设备恢复）。客户端应缓存对方公钥，避免频繁请求；`publicKey` 为 `null` 表示对方未启用 E2EE。

7. **Protobuf**: 实际开发时需要根据 `PushMessage.proto` 文件生成对应语言的代码：
   - Dart: `protoc --dart_out=. PushMessage.proto`
   - Swift: `protoc --swift_out=. PushMessage.proto`

# 一个 Swift 语言版本的简单即使通讯服务器

💧 A project built with the Vapor web framework.

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

## 离线消息

使用 Redis 缓存离线消息，用户发送的消息对方没收到之前都会缓存到 Redis 服务上，当用户收到消息发送了收到回执之后，就会从 Redis 中删除缓存的离线消息

注意⚠️: 在部署之前需要先部署 Redis 服务

## 端到端加密 (E2EE)

支持标准 BIP39 助记词恢复机制：客户端生成助记词派生 X25519 密钥对，服务端仅保存公钥，消息内容全程密文。详细协议见 [API.md](API.md)。

## 邀请码注册与管理员

- 用户注册需填写**邀请码**（`POST /api/v1/register`），邀请码由管理员生成、**单次使用**、带**过期时间**，过期或已使用则无法注册
- 用户拥有 `role` 字段（`user` / `admin`），仅 `admin` 可访问后台管理接口（邀请码生成/列表/撤销）
- 首次引导：部署时设置环境变量 `ADMIN_SETUP_SECRET`（**必填、无默认值**），调用 `POST /api/v1/admin/register` 创建管理员账号；未配置时该接口返回 `503`
- 详情见 [API.md](API.md) 的「后台管理接口」章节

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| `ADMIN_SETUP_SECRET` | 是 | 管理员引导密钥，无默认值；未配置时管理员注册接口不可用（503） |
| `REDIS_PASSWORD` | 部署时是 | Redis 访问密码，无默认值；本地开发可不设置 |
| `REDIS_HOST` | 否 | Redis 地址，默认 `localhost` |
| `DB_PATH` | 否 | SQLite 数据库文件路径，默认 `./chat_server_db.sqlite` |

**本地开发**（不设 Redis 密码时）:
```bash
ADMIN_SETUP_SECRET=dev-secret swift run
```

**docker compose 部署**（密钥必填，缺失时启动报错）:
```bash
cp .env.example .env   # 填写 ADMIN_SETUP_SECRET / REDIS_PASSWORD
docker compose up -d
```

> ⚠️ 本仓库开源，所有密钥均**没有硬编码默认值**。请勿把真实 `.env` 提交到仓库。

## Ubuntu Docker 部署

以下为在 Ubuntu 服务器上使用 Docker Compose 部署的完整流程。

### 1. 安装 Docker 与 Compose

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
```

### 2. 获取代码并配置环境变量

```bash
git clone <仓库地址> && cd ChatServerForSwift
cp .env.example .env

# 生成两个强随机密钥（openssl rand -hex 32）
sed -i "s|ADMIN_SETUP_SECRET=.*|ADMIN_SETUP_SECRET=$(openssl rand -hex 32)|" .env
sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$(openssl rand -hex 32)|" .env
chmod 600 .env   # 勿提交到仓库
```

### 3. 构建并启动

```bash
docker compose build          # 首次构建较久（需编译 Swift）
docker compose up -d
docker compose ps             # redis + app 均应为 Up
curl http://localhost:8080/health   # → OK
```

### 4. 首次初始化管理员

用助记词派生 X25519 公钥后调用引导接口（密钥为 `.env` 中 `ADMIN_SETUP_SECRET` 的值）：

```bash
curl -X POST http://localhost:8080/api/v1/admin/register \
  -H "Content-Type: application/json" \
  -d '{"username":"root","publicKey":"<base64 32字节公钥>","adminSecret":"<ADMIN_SETUP_SECRET 的值>"}'
```

成功返回 `200`，`role` 为 `admin`。

### 5. 登录并生成邀请码

```
POST /api/v1/auth/challenge      → { nonce, ephemeralPublicKey }
POST /api/v1/auth/login          → { token, ... }  （后续请求带 Authorization: Bearer <token>）
POST /api/v1/admin/invitations   → { code, expiresAt, status }   （生成邀请码）
GET  /api/v1/admin/invitations   → 邀请码列表
DELETE /api/v1/admin/invitations/{code}  → 撤销邀请码
```

邀请码单次使用、带过期时间；普通用户凭邀请码调用 `POST /api/v1/register` 注册。

### 6. 运维

- **日志**：`docker compose logs -f app`
- **更新**：`git pull && docker compose build --pull && docker compose up -d`（下次启动自动执行数据库迁移）
- **备份**：SQLite 数据库位于 `./data/chat_server_db.sqlite`（建议定期备份该目录）；Redis 中仅存离线消息缓存，可随时丢弃
- **重启策略**：服务已配置 `restart: unless-stopped`，主机重启后自动拉起

### 7. 安全建议

- 前端建议加 Caddy/nginx 反代启用 HTTPS（容器对外暴露 8080，443 由反代处理）
- 防火墙：`sudo ufw allow 443`（或 8080）；Redis 已不暴露宿主端口且需密码
- 切勿把 `.env` 提交到仓库（`.gitignore` 已忽略）；更换密钥需同步更新 `POST /api/v1/admin/register` 的请求

## 项目架构

    Sources/
    ├── App/                         # 基础设施层 (Infrastructure)
    │   ├── Vapor/                   # Vapor Web 框架相关
    │   │   ├── Controllers/         # HTTP 控制器
    │   │   │   ├── UserController.swift
    │   │   │   └── ChatWebSocketController.swift
    │   │   ├── Middlewares/         # 中间件
    │   │   │   └── AuthMiddleware.swift
    │   │   └── Routes/
    │   │       └── routes.swift
    │   ├── Persistence/             # 数据持久化
    │   │   ├── Fluent/              # Fluent ORM 实现
    │   │   │   ├── Models/          # Fluent 模型
    │   │   │   │   ├── UserFluentModel.swift
    │   │   │   │   └── InvitationCodeFluentModel.swift
    │   │   │   ├── Migrations/
    │   │   │   │   └── CreateTables.swift
    │   │   │   ├── FluentUserRepository.swift
    │   │   │   ├── FluentKeyRepository.swift
    │   │   │   └── FluentInvitationCodeRepository.swift
    │   │   └── Redis/               # Redis 实现
    │   │       └── RedisMessageCache.swift
    │   └── configure.swift
    ├── Domain/                      # 领域层 (Entities)
    │   ├── Entities/                # 领域实体
    │   │   ├── User.swift
    │   │   ├── UserKey.swift        # 用户公钥实体 (E2EE)
    │   │   ├── InvitationCode.swift # 邀请码实体
    │   │   └── ChatMessage.swift
    │   ├── ValueObjects/            # 值对象
    │   │   ├── Password.swift
    │   │   ├── PublicKey.swift      # 公钥值对象 (E2EE)
    │   │   ├── Username.swift
    │   │   ├── Nickname.swift
    │   │   ├── UserRole.swift       # 用户角色（admin / user）
    │   │   └── DomainError.swift
    │   └── Protocols/               # 领域协议
    │       ├── UserRepository.swift
    │       ├── KeyRepository.swift  # 公钥仓库 (E2EE)
    │       ├── InvitationCodeRepository.swift
    │       ├── MessageCache.swift
    │       └── ChatConnectionManager.swift
    ├── Application/                 # 应用层 (Use Cases)
    │   ├── UseCases/                # 用例/交互器
    │   │   ├── User/
    │   │   │   ├── RegisterUser.swift
    │   │   │   ├── LoginUser.swift
    │   │   │   ├── ChangePassword.swift
    │   │   │   ├── ChangeNickname.swift
    │   │   │   ├── GetUserProfile.swift
    │   │   │   ├── UploadPublicKey.swift   # 上传公钥 (E2EE)
    │   │   │   └── GetPublicKey.swift      # 获取公钥 (E2EE)
    │   │   └── Chat/
    │   │       ├── SendMessage.swift
    │   │       └── ProcessReceipt.swift
    │   ├── DTOs/                    # 数据传输对象
    │   │   ├── UserDTOs.swift
    │   │   ├── KeyDTOs.swift        # 公钥 DTO (E2EE)
    │   │   └── ChatDTOs.swift
    │   └── Errors/                  # 应用层错误
    │       └── ApplicationError.swift
    ├── ChatServerForSwift/          # 入口
    │   └── entrypoint.swift
    └── Proto/                       # Protobuf 消息定义
        └── PushMessage.pb.swift

## 架构特点

- Domain层独立：Entities、ValueObjects、Protocols 不依赖任何外部框架
- 依赖向内指向：Application层依赖Domain层，Infrastructure层依赖Application层
- 可测试性：业务逻辑（UseCases）不依赖Vapor/Fluent，易于单元测试
- 可替换性：可以轻松替换数据库（Fluent）或Web框架（Vapor）

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)

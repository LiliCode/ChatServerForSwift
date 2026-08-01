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

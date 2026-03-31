# ChatServerForSwift

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
    │   │   │   │   └── OrganizationFluentModel.swift
    │   │   │   ├── Migrations/
    │   │   │   │   └── CreateTables.swift
    │   │   │   ├── FluentUserRepository.swift
    │   │   │   └── FluentOrganizationRepository.swift
    │   │   └── Redis/               # Redis 实现
    │   │       └── RedisMessageCache.swift
    │   └── configure.swift
    ├── Domain/                      # 领域层 (Entities)
    │   ├── Entities/                # 领域实体
    │   │   ├── User.swift
    │   │   ├── Organization.swift
    │   │   └── ChatMessage.swift
    │   ├── ValueObjects/            # 值对象
    │   │   ├── Password.swift
    │   │   ├── Username.swift
    │   │   ├── Nickname.swift
    │   │   ├── OrganizationCode.swift
    │   │   └── DomainError.swift
    │   └── Protocols/               # 领域协议
    │       ├── UserRepository.swift
    │       ├── OrganizationRepository.swift
    │       ├── MessageCache.swift
    │       └── ChatConnectionManager.swift
    ├── Application/                 # 应用层 (Use Cases)
    │   ├── UseCases/                # 用例/交互器
    │   │   ├── User/
    │   │   │   ├── RegisterUser.swift
    │   │   │   ├── LoginUser.swift
    │   │   │   ├── ChangePassword.swift
    │   │   │   ├── ChangeNickname.swift
    │   │   │   └── GetUserProfile.swift
    │   │   └── Chat/
    │   │       ├── SendMessage.swift
    │   │       └── ProcessReceipt.swift
    │   ├── DTOs/                    # 数据传输对象
    │   │   ├── UserDTOs.swift
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

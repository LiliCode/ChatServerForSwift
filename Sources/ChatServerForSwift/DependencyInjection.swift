import Vapor

// MARK: - Application 扩展用于依赖注入

extension Application {
    // MARK: - Repositories
    
    var userRepository: UserRepository {
        FluentUserRepository(db: db)
    }
    
    var organizationRepository: OrganizationRepository {
        FluentOrganizationRepository(db: db)
    }
    
    var messageCache: MessageCache {
        RedisMessageCache(redis: redis)
    }
    
    // MARK: - Use Cases
    
    var registerUser: RegisterUser {
        RegisterUser(
            userRepository: userRepository,
            orgRepository: organizationRepository
        )
    }
    
    var loginUser: LoginUser {
        LoginUser(userRepository: userRepository)
    }
    
    var changePassword: ChangePassword {
        ChangePassword(userRepository: userRepository)
    }
    
    var changeNickname: ChangeNickname {
        ChangeNickname(userRepository: userRepository)
    }
    
    var getUserProfile: GetUserProfile {
        GetUserProfile(userRepository: userRepository)
    }
    
    var sendMessage: SendMessage {
        SendMessage(
            userRepository: userRepository,
            connectionManager: WebSocketConnectionManager.shared,
            messageCache: messageCache
        )
    }
    
    var processReceipt: ProcessReceipt {
        ProcessReceipt(messageCache: messageCache)
    }
}

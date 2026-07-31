import Vapor

// MARK: - Application 扩展用于依赖注入

extension Application {
    // MARK: - Repositories
    
	var userRepository: any UserRepository {
        FluentUserRepository(db: db)
    }
    
	var organizationRepository: any OrganizationRepository {
        FluentOrganizationRepository(db: db)
    }
    
	var messageCache: any MessageCache {
        RedisMessageCache(redis: redis)
    }
    
	var keyRepository: any KeyRepository {
        FluentKeyRepository(db: db)
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
    
    var uploadPublicKey: UploadPublicKey {
        UploadPublicKey(keyRepository: keyRepository)
    }
    
    var getPublicKey: GetPublicKey {
        GetPublicKey(keyRepository: keyRepository)
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

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
    
	var tokenRepository: any TokenRepository {
        FluentTokenRepository(db: db)
    }
    
    // MARK: - Use Cases
    
    var registerUser: RegisterUser {
        RegisterUser(
            userRepository: userRepository,
            orgRepository: organizationRepository,
            keyRepository: keyRepository
        )
    }
    
    var createAuthChallenge: CreateAuthChallenge {
        CreateAuthChallenge(
            userRepository: userRepository,
            keyRepository: keyRepository,
            challengeStore: AuthChallengeStore.shared
        )
    }
    
    var loginWithMnemonic: LoginWithMnemonic {
        LoginWithMnemonic(
            userRepository: userRepository,
            keyRepository: keyRepository,
            tokenRepository: tokenRepository,
            challengeStore: AuthChallengeStore.shared
        )
    }
    
    var changeNickname: ChangeNickname {
        ChangeNickname(userRepository: userRepository)
    }
    
    var getUserProfile: GetUserProfile {
        GetUserProfile(userRepository: userRepository)
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

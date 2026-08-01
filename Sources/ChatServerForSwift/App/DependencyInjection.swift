import Vapor

// MARK: - Application 扩展用于依赖注入

extension Application {
    // MARK: - Repositories
    
	var userRepository: any UserRepository {
        FluentUserRepository(db: db)
    }
    
	var invitationCodeRepository: any InvitationCodeRepository {
        FluentInvitationCodeRepository(db: db)
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
    
    // MARK: - 管理员密钥
    
    /// 管理员引导密钥（环境变量 ADMIN_SETUP_SECRET，必填，无默认值）
    private struct AdminSetupSecretKey: StorageKey {
        typealias Value = String
    }
    
    var adminSetupSecret: String? {
        get {
            storage[AdminSetupSecretKey.self] ?? Environment.get("ADMIN_SETUP_SECRET")
        }
        set {
            storage[AdminSetupSecretKey.self] = newValue
        }
    }
    
    // MARK: - Use Cases
    
    var registerUser: RegisterUser {
        RegisterUser(
            userRepository: userRepository,
            invitationCodeRepository: invitationCodeRepository,
            keyRepository: keyRepository
        )
    }
    
    var adminRegisterUser: AdminRegisterUser {
        AdminRegisterUser(
            userRepository: userRepository,
            keyRepository: keyRepository,
            expectedSecret: adminSetupSecret
        )
    }
    
    var createInvitationCode: CreateInvitationCode {
        CreateInvitationCode(invitationCodeRepository: invitationCodeRepository)
    }
    
    var listInvitationCodes: ListInvitationCodes {
        ListInvitationCodes(invitationCodeRepository: invitationCodeRepository)
    }
    
    var revokeInvitationCode: RevokeInvitationCode {
        RevokeInvitationCode(invitationCodeRepository: invitationCodeRepository)
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

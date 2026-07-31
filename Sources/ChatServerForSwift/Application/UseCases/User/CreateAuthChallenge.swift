import Foundation
import CryptoKit

/// 发起登录挑战用例（X25519 DH 挑战-响应）
public struct CreateAuthChallenge: Sendable {
    private let userRepository: any UserRepository
    private let keyRepository: any KeyRepository
    private let challengeStore: AuthChallengeStore
    
    public init(
        userRepository: any UserRepository,
        keyRepository: any KeyRepository,
        challengeStore: AuthChallengeStore
    ) {
        self.userRepository = userRepository
        self.keyRepository = keyRepository
        self.challengeStore = challengeStore
    }
    
    public func execute(username: String) async throws -> AuthChallengeResponse {
        // 1. 用户必须存在且已绑定公钥
        guard let user = try await userRepository.findByUsername(username) else {
            throw ApplicationError.userNotFound
        }
        guard try await keyRepository.findPublicKey(for: user.id) != nil else {
            throw ApplicationError.publicKeyNotSet
        }
        
        // 2. 生成一次性临时 X25519 密钥对
        let ephemeralKey = Curve25519.KeyAgreement.PrivateKey()
        let nonce = UUID().uuidString
        
        // 3. 存储临时私钥（TTL 5 分钟，单次使用）
        await challengeStore.store(
            nonce: nonce,
            username: username,
            privateKey: ephemeralKey.rawRepresentation
        )
        
        return AuthChallengeResponse(
            nonce: nonce,
            ephemeralPublicKey: ephemeralKey.publicKey.rawRepresentation.base64EncodedString()
        )
    }
}

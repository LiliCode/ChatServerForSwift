import Foundation
import CryptoKit

/// 助记词登录用例（X25519 DH 挑战-响应验证私钥持有，颁发会话令牌）
public struct LoginWithMnemonic: Sendable {
    private let userRepository: any UserRepository
    private let keyRepository: any KeyRepository
    private let tokenRepository: any TokenRepository
    private let challengeStore: AuthChallengeStore
    
    public init(
        userRepository: any UserRepository,
        keyRepository: any KeyRepository,
        tokenRepository: any TokenRepository,
        challengeStore: AuthChallengeStore
    ) {
        self.userRepository = userRepository
        self.keyRepository = keyRepository
        self.tokenRepository = tokenRepository
        self.challengeStore = challengeStore
    }
    
    public func execute(_ input: MnemonicLoginRequest) async throws -> (token: String, user: UserDTO) {
        // 1. 取出挑战（一次性，防重放）
        guard let (challengeUsername, ephPrivData) = await challengeStore.take(nonce: input.nonce),
              challengeUsername == input.username else {
            throw ApplicationError.invalidChallenge
        }
        
        // 2. 查找用户及其绑定的公钥
        guard let user = try await userRepository.findByUsername(input.username) else {
            throw ApplicationError.userNotFound
        }
        guard let storedKey = try await keyRepository.findPublicKey(for: user.id),
              let storedKeyData = Data(base64Encoded: storedKey) else {
            throw ApplicationError.publicKeyNotSet
        }
        
        // 3. 用临时私钥 + 用户存储的公钥计算共享密钥，校验 proof
        do {
            let serverEphPriv = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: ephPrivData)
            let clientPub = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: storedKeyData)
            let sharedSecret = try serverEphPriv.sharedSecretFromKeyAgreement(with: clientPub)
            
            let expectedProof = LoginWithMnemonic.computeProof(
                sharedSecret: sharedSecret,
                nonce: input.nonce,
                username: input.username
            )
            guard let providedProof = Data(base64Encoded: input.proof),
                  LoginWithMnemonic.constantTimeEqual(expectedProof, providedProof) else {
                throw ApplicationError.invalidKeyProof
            }
        } catch let error as ApplicationError {
            throw error
        } catch {
            throw ApplicationError.invalidKeyProof
        }
        
        // 4. 颁发会话令牌
        let authToken = try await tokenRepository.create(for: user.id)
        
        let userDTO = UserDTO(
            id: user.id.uuidString,
            username: user.username,
            nickname: user.nickname,
            organizationCode: user.organizationCode,
            createdAt: user.createdAt
        )
        return (authToken.token, userDTO)
    }
    
    /// proof = HMAC-SHA256(key: 共享密钥原始字节, data: nonce || username)
    static func computeProof(sharedSecret: SharedSecret, nonce: String, username: String) -> Data {
        let key = SymmetricKey(data: sharedSecret.withUnsafeBytes { Data($0) })
        let message = Data((nonce + username).utf8)
        return Data(HMAC<SHA256>.authenticationCode(for: message, using: key))
    }
    
    static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var diff: UInt8 = 0
        for i in 0..<lhs.count {
            diff |= lhs[i] ^ rhs[i]
        }
        return diff == 0
    }
}

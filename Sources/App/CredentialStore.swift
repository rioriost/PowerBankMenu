import Foundation

struct SolixCredentials: Codable, Equatable {
    var email: String
    var password: String
    var countryId: String
}

protocol CredentialStoring {
    func load() throws -> SolixCredentials?
    func save(_ credentials: SolixCredentials) throws
    func clear() throws
}

enum CredentialStoreError: LocalizedError {
    case invalidStoredCredentials
    case saveVerificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidStoredCredentials:
            return "Stored credentials could not be decoded."
        case .saveVerificationFailed:
            return "Stored credentials did not match the saved credentials."
        }
    }
}

final class CredentialStore: CredentialStoring, @unchecked Sendable {
    static let shared = CredentialStore()

    private let keychain = KeychainDataStore(service: AuthStorageIdentifiers.credentialsService)
    private let legacyKeychain = KeychainDataStore(
        service: AuthStorageIdentifiers.credentialsService,
        usesDataProtectionKeychain: false
    )
    private let loginResponseKeychain = KeychainDataStore(
        service: AuthStorageIdentifiers.loginResponseService
    )
    private let legacyLoginResponseKeychain = KeychainDataStore(
        service: AuthStorageIdentifiers.loginResponseService,
        usesDataProtectionKeychain: false
    )
    private let account = AuthStorageIdentifiers.defaultAccount
    private let legacyDefaultsKey = AuthStorageIdentifiers.legacyCredentialsDefaultsKey

    private init() {}

    func load() throws -> SolixCredentials? {
        if let data = try keychain.load(account: account) {
            guard let credentials = try? JSONDecoder().decode(SolixCredentials.self, from: data)
            else { throw CredentialStoreError.invalidStoredCredentials }
            removeLegacyDefaults()
            return credentials
        }

        if let legacyData = try legacyKeychain.load(account: account) {
            guard
                let credentials = try? JSONDecoder().decode(
                    SolixCredentials.self,
                    from: legacyData
                )
            else {
                try legacyKeychain.delete(account: account)
                removeLegacyDefaults()
                removeLegacyLoginResponseDefaults()
                throw CredentialStoreError.invalidStoredCredentials
            }
            try keychain.save(legacyData, account: account)
            try legacyKeychain.delete(account: account)
            removeLegacyDefaults()
            return credentials
        }

        guard let defaultsData = UserDefaults.standard.data(forKey: legacyDefaultsKey) else {
            removeLegacyLoginResponseDefaults()
            return nil
        }
        guard
            let credentials = try? JSONDecoder().decode(SolixCredentials.self, from: defaultsData)
        else {
            removeLegacyDefaults()
            removeLegacyLoginResponseDefaults()
            throw CredentialStoreError.invalidStoredCredentials
        }
        try keychain.save(defaultsData, account: account)
        removeLegacyDefaults()
        return credentials
    }

    func save(_ credentials: SolixCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try keychain.save(data, account: account)
        guard
            let savedData = try keychain.load(account: account),
            let savedCredentials = try? JSONDecoder().decode(
                SolixCredentials.self,
                from: savedData
            ),
            savedCredentials == credentials
        else {
            throw CredentialStoreError.saveVerificationFailed
        }
        try? legacyKeychain.delete(account: account)
        removeLegacyDefaults()
    }

    func clear() throws {
        try keychain.delete(account: account)
        try? legacyKeychain.delete(account: account)
        try loginResponseKeychain.delete(account: account)
        try? legacyLoginResponseKeychain.delete(account: account)
        removeLegacyDefaults()
        removeLegacyLoginResponseDefaults()
    }

    private func removeLegacyDefaults() {
        UserDefaults.standard.removeObject(forKey: legacyDefaultsKey)
    }

    private func removeLegacyLoginResponseDefaults() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix(AuthStorageIdentifiers.legacyLoginResponseDefaultsPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}

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
            else {
                try keychain.delete(account: account)
                try removeOrphanedLoginResponse()
                removeLegacyDefaults()
                removeLegacyLoginResponseDefaults()
                return nil
            }
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
                try removeOrphanedLoginResponse()
                removeLegacyDefaults()
                removeLegacyLoginResponseDefaults()
                return nil
            }
            try keychain.save(legacyData, account: account)
            try legacyKeychain.delete(account: account)
            removeLegacyDefaults()
            return credentials
        }

        guard let defaultsData = UserDefaults.standard.data(forKey: legacyDefaultsKey) else {
            try removeOrphanedLoginResponse()
            removeLegacyLoginResponseDefaults()
            return nil
        }
        guard
            let credentials = try? JSONDecoder().decode(SolixCredentials.self, from: defaultsData)
        else {
            removeLegacyDefaults()
            try removeOrphanedLoginResponse()
            removeLegacyLoginResponseDefaults()
            return nil
        }
        try keychain.save(defaultsData, account: account)
        removeLegacyDefaults()
        return credentials
    }

    func save(_ credentials: SolixCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        try keychain.save(data, account: account)
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

    private func removeOrphanedLoginResponse() throws {
        try loginResponseKeychain.delete(account: account)
        try? legacyLoginResponseKeychain.delete(account: account)
    }

    private func removeLegacyLoginResponseDefaults() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix(AuthStorageIdentifiers.legacyLoginResponseDefaultsPrefix) {
            defaults.removeObject(forKey: key)
        }
    }
}

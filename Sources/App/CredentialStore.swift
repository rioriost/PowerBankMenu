import Foundation
import Security

struct SolixCredentials: Codable, Equatable {
    var email: String
    var password: String
    var countryId: String
}

protocol CredentialStoring {
    func load() -> SolixCredentials?
    func save(_ credentials: SolixCredentials) -> Bool
    func clear() -> Bool
}

final class CredentialStore: CredentialStoring, @unchecked Sendable {
    static let shared = CredentialStore()

    private let service = "st.rio.powerbankmenu.credentials"
    private let account = "default"

    private init() {}

    func load() -> SolixCredentials? {
        #if DEBUG
            return loadFromDefaults()
        #else
            return loadFromKeychain()
        #endif
    }

    @discardableResult
    func save(_ credentials: SolixCredentials) -> Bool {
        #if DEBUG
            return saveToDefaults(credentials)
        #else
            return saveToKeychain(credentials)
        #endif
    }

    @discardableResult
    func clear() -> Bool {
        #if DEBUG
            return clearDefaults()
        #else
            return clearKeychain()
        #endif
    }

    // MARK: - UserDefaults (Debug)

    private let defaultsKey = "PowerBankMenuCredentials"

    private func loadFromDefaults() -> SolixCredentials? {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(SolixCredentials.self, from: data)
    }

    private func saveToDefaults(_ credentials: SolixCredentials) -> Bool {
        guard let data = try? JSONEncoder().encode(credentials) else { return false }
        UserDefaults.standard.set(data, forKey: defaultsKey)
        return true
    }

    private func clearDefaults() -> Bool {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
        return true
    }

    // MARK: - Keychain (Release)

    private func loadFromKeychain() -> SolixCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(SolixCredentials.self, from: data)
    }

    private func saveToKeychain(_ credentials: SolixCredentials) -> Bool {
        guard let data = try? JSONEncoder().encode(credentials) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess {
            return true
        }
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
        return false
    }

    private func clearKeychain() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

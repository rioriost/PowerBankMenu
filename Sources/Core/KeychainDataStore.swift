import Foundation
import Security

enum AuthStorageIdentifiers {
    static let credentialsService = "st.rio.powerbankmenu.credentials"
    static let loginResponseService = "st.rio.powerbankmenu.login-response"
    static let defaultAccount = "default"
    static let legacyCredentialsDefaultsKey = "PowerBankMenuCredentials"
    static let legacyLoginResponseDefaultsPrefix = "PowerBankLoginResponse:"
}

enum KeychainDataStoreError: LocalizedError {
    case operationFailed(operation: String, status: OSStatus)

    var errorDescription: String? {
        switch self {
        case .operationFailed(let operation, let status):
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            return "Keychain \(operation) failed (OSStatus \(status)): \(message)"
        }
    }
}

/// Stores opaque data in an app-private generic-password item.
///
/// App builds use the Data Protection Keychain so access is scoped to the
/// signed app identifier. Command-line test builds use the legacy macOS
/// keychain because they don't carry an application-identifier entitlement.
struct KeychainDataStore: Sendable {
    let service: String
    let usesDataProtectionKeychain: Bool

    init(service: String, usesDataProtectionKeychain: Bool = true) {
        self.service = service
        self.usesDataProtectionKeychain = usesDataProtectionKeychain
    }

    func load(account: String) throws -> Data? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw KeychainDataStoreError.operationFailed(operation: "read", status: status)
        }
        guard let data = result as? Data else {
            throw KeychainDataStoreError.operationFailed(
                operation: "read",
                status: errSecDecode
            )
        }
        return data
    }

    func save(_ data: Data, account: String) throws {
        let query = baseQuery(account: account)
        let attributes = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainDataStoreError.operationFailed(
                operation: "update",
                status: updateStatus
            )
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        if usesDataProtectionKeychain {
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecDuplicateItem {
            let retryStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            guard retryStatus == errSecSuccess else {
                throw KeychainDataStoreError.operationFailed(
                    operation: "update",
                    status: retryStatus
                )
            }
            return
        }
        guard addStatus == errSecSuccess else {
            throw KeychainDataStoreError.operationFailed(operation: "save", status: addStatus)
        }
    }

    func delete(account: String) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainDataStoreError.operationFailed(operation: "delete", status: status)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if usesDataProtectionKeychain {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        return query
    }
}

import Foundation
import Security

enum AuthStorageIdentifiers {
    static let credentialsService = "st.rio.powerbankmenu.credentials"
    static let loginResponseService = "st.rio.powerbankmenu.login-response"
    static let defaultAccount = "default"
    static let legacyCredentialsDefaultsKey = "PowerBankMenuCredentials"
    static let legacyLoginResponseDefaultsPrefix = "PowerBankLoginResponse:"

    static var configuredAccessGroup: String? {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return nil }
        guard
            let value = Bundle.main.object(
                forInfoDictionaryKey: "PowerBankKeychainAccessGroup"
            ) as? String,
            !value.isEmpty
        else {
            return nil
        }
        return value
    }
}

enum KeychainDataStoreError: LocalizedError {
    case operationFailed(operation: String, status: OSStatus)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .operationFailed(let operation, let status):
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error"
            return "Keychain \(operation) failed (OSStatus \(status)): \(message)"
        case .verificationFailed:
            return "Keychain save verification failed."
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
    let accessGroup: String?

    init(
        service: String,
        usesDataProtectionKeychain: Bool = true,
        accessGroup: String? = AuthStorageIdentifiers.configuredAccessGroup
    ) {
        self.service = service
        self.usesDataProtectionKeychain = usesDataProtectionKeychain
        self.accessGroup = usesDataProtectionKeychain ? accessGroup : nil
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
            try verifySavedData(data, account: account)
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
            try verifySavedData(data, account: account)
            return
        }
        guard addStatus == errSecSuccess else {
            throw KeychainDataStoreError.operationFailed(operation: "save", status: addStatus)
        }
        try verifySavedData(data, account: account)
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
        query[kSecUseDataProtectionKeychain as String] = usesDataProtectionKeychain
        if usesDataProtectionKeychain {
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
        }
        return query
    }

    private func verifySavedData(_ expected: Data, account: String) throws {
        guard try load(account: account) == expected else {
            throw KeychainDataStoreError.verificationFailed
        }
    }
}

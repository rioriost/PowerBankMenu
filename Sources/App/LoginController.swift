import Foundation

enum LoginControllerError: Error, CustomStringConvertible {
    case missingCredentials
    case backoffActive(TimeInterval)
    case authenticationFailed(Error)

    var description: String {
        switch self {
        case .missingCredentials:
            return "Missing credentials."
        case .backoffActive(let remaining):
            let seconds = max(0, Int(remaining))
            return "Login backoff active. Try again in \(seconds) seconds."
        case .authenticationFailed(let error):
            return "Authentication failed: \(error)"
        }
    }
}

final class LoginController {
    struct Configuration {
        var backoffSeconds: TimeInterval = 600
        var logPrefix: String = "[LoginController]"
        var logger: ((String) -> Void)? = nil
        var sessionConfiguration: ApiSessionConfiguration = ApiSessionConfiguration()
    }

    private let credentialStore: CredentialStoring
    private var config: Configuration
    private var session: ApiSession?
    private var lastFailureAt: Date?
    private var lastFailureError: Error?
    private(set) var lastSuccessfulLoginAt: Date?

    init(
        credentialStore: CredentialStoring = CredentialStore.shared,
        configuration: Configuration = Configuration()
    ) {
        self.credentialStore = credentialStore
        self.config = configuration
    }

    func updateConfiguration(_ configuration: Configuration) {
        self.config = configuration
    }

    func saveCredentials(_ credentials: SolixCredentials) throws {
        try credentialStore.save(credentials)
        clearBackoff()
    }

    func clearCredentials() throws {
        try credentialStore.clear()
    }

    func cachedCredentials() -> SolixCredentials? {
        try? credentialStore.load()
    }

    func authenticateFromSettings(_ credentials: SolixCredentials) async -> Result<
        ApiSession, Error
    > {
        do {
            let session = try ApiSession(
                email: credentials.email,
                password: credentials.password,
                countryId: credentials.countryId,
                configuration: config.sessionConfiguration
            )
            let success = try await session.authenticate(restart: true)
            if success {
                return .success(session)
            }
            return .failure(ApiSessionError.authenticationFailed)
        } catch {
            return .failure(error)
        }
    }

    func authenticate(fromSettings: Bool = false) async throws -> ApiSession {
        if !fromSettings, let remaining = backoffRemaining(), remaining > 0 {
            log("Backoff active (\(Int(remaining))s remaining).")
            throw LoginControllerError.backoffActive(remaining)
        }

        guard let credentials = try credentialStore.load() else {
            log("Missing credentials.")
            throw LoginControllerError.missingCredentials
        }

        if fromSettings {
            clearBackoff()
        }

        let apiSession = try buildOrUpdateSession(with: credentials)

        log("Authenticating (cache-first).")
        do {
            let success = try await apiSession.authenticate(restart: false)
            if success {
                lastFailureAt = nil
                lastFailureError = nil
                lastSuccessfulLoginAt = Date()
                log("Authentication succeeded.")
                return apiSession
            }

            let error = ApiSessionError.authenticationFailed
            recordFailure(error, applyBackoff: !fromSettings)
            throw LoginControllerError.authenticationFailed(error)
        } catch {
            recordFailure(error, applyBackoff: !fromSettings)
            throw LoginControllerError.authenticationFailed(error)
        }
    }

    func forceReauthenticate(fromSettings: Bool = false) async throws -> ApiSession {
        if !fromSettings, let remaining = backoffRemaining(), remaining > 0 {
            log("Backoff active (\(Int(remaining))s remaining).")
            throw LoginControllerError.backoffActive(remaining)
        }

        guard let credentials = try credentialStore.load() else {
            log("Missing credentials.")
            throw LoginControllerError.missingCredentials
        }

        if fromSettings {
            clearBackoff()
        }

        let apiSession = try buildOrUpdateSession(with: credentials)
        log("Forcing re-authentication (restart=true).")

        do {
            let success = try await apiSession.authenticate(restart: true)
            if success {
                lastFailureAt = nil
                lastFailureError = nil
                lastSuccessfulLoginAt = Date()
                log("Re-authentication succeeded.")
                return apiSession
            }

            let error = ApiSessionError.authenticationFailed
            recordFailure(error, applyBackoff: !fromSettings)
            throw LoginControllerError.authenticationFailed(error)
        } catch {
            recordFailure(error, applyBackoff: !fromSettings)
            throw LoginControllerError.authenticationFailed(error)
        }
    }

    private func buildOrUpdateSession(with credentials: SolixCredentials) throws -> ApiSession {
        if let session = session, session.email == credentials.email {
            session.updateCredentials(
                password: credentials.password,
                countryId: credentials.countryId
            )
            return session
        }

        let session = try ApiSession(
            email: credentials.email,
            password: credentials.password,
            countryId: credentials.countryId,
            configuration: config.sessionConfiguration
        )
        self.session = session
        return session
    }

    private func backoffRemaining() -> TimeInterval? {
        guard let lastFailureAt else { return nil }
        let elapsed = Date().timeIntervalSince(lastFailureAt)
        let remaining = config.backoffSeconds - elapsed
        return remaining > 0 ? remaining : nil
    }

    private func clearBackoff() {
        lastFailureAt = nil
        lastFailureError = nil
    }

    private func recordFailure(_ error: Error, applyBackoff: Bool = true) {
        if applyBackoff {
            lastFailureAt = Date()
        }
        lastFailureError = error
        log("Authentication failed: \(error)")
    }

    private func log(_ message: String) {
        config.logger?("\(config.logPrefix) \(message)")
    }
}

import Foundation
import ServiceManagement

enum AppSettingsKeys {
    static let debugLogEnabled = "PowerBankMenuDebugLogEnabled"
}

@MainActor
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isDebugLogEnabled: Bool {
        get {
            defaults.bool(forKey: AppSettingsKeys.debugLogEnabled)
        }
        set {
            defaults.set(newValue, forKey: AppSettingsKeys.debugLogEnabled)
            AppLogger.shared.setFileLoggingEnabled(newValue)
        }
    }

    var isLaunchAtLoginEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if enabled {
            guard service.status != .enabled else { return }
            try service.register()
        } else {
            guard service.status == .enabled else { return }
            try service.unregister()
        }
    }
}

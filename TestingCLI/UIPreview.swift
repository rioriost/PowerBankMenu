// Standalone UI fixture: no account access, network, preferences, or login-item writes.
import Cocoa

struct SolixCredentials {
    var email: String
    var password: String
    var countryId: String
}

@MainActor final class AppSettings {
    static let shared = AppSettings()
    var isDebugLogEnabled = false
    var isLaunchAtLoginEnabled = false
    func setLaunchAtLoginEnabled(_ enabled: Bool) throws { isLaunchAtLoginEnabled = enabled }
}

enum AppLogger {
    static func log(_ message: String) {}
}

@main @MainActor final class UIPreview: NSObject, NSApplicationDelegate {
    private var settings: AccountSettingsWindowController?
    private var status: StatusBarController?
    private let state = SolixAppState()

    static func main() {
        let app = NSApplication.shared
        let delegate = UIPreview()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let url = Bundle.main.url(forResource: "preview-icon", withExtension: "png") {
            NSApp.applicationIconImage = NSImage(contentsOf: url)
        }
        let appearance = ProcessInfo.processInfo.environment["UI_APPEARANCE"] ?? "light"
        NSApp.appearance = NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)
        status = StatusBarController(appState: state)
        status?.onAccountSettings = { [weak self] in self?.showSettings() }
        status?.onAbout = { [weak self] in self?.showAbout() }
        let scenario = ProcessInfo.processInfo.environment["UI_SCENARIO"] ?? "populated"
        if scenario == "populated" {
            state.isAuthenticated = true
            state.updateDevice(id: "one", name: "SOLIX C1000", batteryPercent: 82, outputWatts: 125, inputWatts: 240)
            state.updateDevice(id: "two", name: "SOLIX — Living Room Backup Battery", batteryPercent: 7, outputWatts: 80, inputWatts: 0)
            state.updateDevice(id: "three", name: "SOLIX C300")
        } else if scenario == "error" {
            state.lastErrorMessage = "Connection unavailable. Check your network and try again."
        }
        let previewItem = NSMenuItem(title: "Device Preview", action: nil, keyEquivalent: "")
        previewItem.submenu = status?.menu
        NSApp.mainMenu?.addItem(previewItem)
        showSettings()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showSettings() }
        return true
    }

    @objc private func showSettings() {
        if settings == nil {
            settings = AccountSettingsWindowController(credentials: nil, onVerify: { _ in
                print("UI preview: verification started")
                try? await Task.sleep(for: .seconds(15))
                print("UI preview: verification completed")
                if ProcessInfo.processInfo.environment["UI_VERIFY_SUCCESS"] == "1" { return .success(()) }
                return .failure(NSError(domain: "UIPreview", code: 1, userInfo: [NSLocalizedDescriptionKey:
                    AppLocalization.isJapanese
                    ? "接続できませんでした。ネットワーク接続とアカウント情報を確認して、もう一度お試しください。"
                    : "Could not connect. Check your network connection and account details, then try again."]))
            }, onClose: { [weak self] in
                print("UI preview: settings closed")
                self?.settings = nil
            })
        }
        settings?.present()
    }

    @objc private func showAbout() { AboutWindowController.shared.show() }
}

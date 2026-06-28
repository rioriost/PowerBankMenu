import Cocoa

@main
@MainActor
final class SolixMenuApp: NSObject, NSApplicationDelegate {
    private let coordinator = SolixAppCoordinator()
    private var statusBarController: StatusBarController?
    private var accountSettingsWindow: AccountSettingsWindowController?
    private let terminationReason = "PowerBankMenu status item"

    private func logLifecycle(_ message: String) {
        AppLogger.log("[PowerBankMenuApp] \(message)")
    }

    static func main() {
        let app = NSApplication.shared
        let delegate = SolixMenuApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        logLifecycle("applicationDidFinishLaunching")
        ProcessInfo.processInfo.disableAutomaticTermination(terminationReason)
        NSLog("PowerBankMenu: configuring status bar controller.")
        statusBarController = StatusBarController(appState: coordinator.appState)
        NSLog("PowerBankMenu: status bar controller configured: \(statusBarController != nil).")
        logLifecycle("status bar controller configured: \(statusBarController != nil)")
        statusBarController?.onAccountSettings = { [weak self] in
            self?.logLifecycle("account settings requested")
            self?.showAccountSettings()
        }
        statusBarController?.onAbout = { [weak self] in
            self?.logLifecycle("about requested")
            self?.showAbout()
        }
        statusBarController?.onQuit = {
            AppLogger.log("[PowerBankMenuApp] quit requested from status bar")
            NSApp.terminate(nil)
        }
        logLifecycle("starting coordinator task")
        Task {
            AppLogger.log("[PowerBankMenuApp] coordinator.start begin")
            await coordinator.start()
            AppLogger.log("[PowerBankMenuApp] coordinator.start end")
        }
    }

    private func showAccountSettings() {
        if let accountSettingsWindow {
            accountSettingsWindow.present()
            return
        }
        let credentials = CredentialStore.shared.load()
        let window = AccountSettingsWindowController(
            credentials: credentials,
            onVerify: { [weak self] credentials in
                guard let self else {
                    return .failure(ApiSessionError.authenticationFailed)
                }
                let result = await self.coordinator.applySettings(credentials)
                if case .success = result {
                    self.closeAccountSettingsWindow()
                }
                return result
            },
            onCancel: { [weak self] in
                self?.closeAccountSettingsWindow()
            },
            onClose: { [weak self] in
                self?.closeAccountSettingsWindow()
            }
        )
        accountSettingsWindow = window
        statusBarController?.setAccountSettingsEnabled(false)
        window.present()
    }

    private func closeAccountSettingsWindow() {
        accountSettingsWindow = nil
        statusBarController?.setAccountSettingsEnabled(true)
    }

    private func showAbout() {
        AboutWindowController.shared.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        logLifecycle("applicationWillTerminate")
        ProcessInfo.processInfo.enableAutomaticTermination(terminationReason)
        logLifecycle("calling coordinator.stop")
        coordinator.stop()
        logLifecycle("applicationWillTerminate complete")
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        logLifecycle("applicationShouldTerminate")
        return .terminateNow
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        logLifecycle("applicationDidBecomeActive")
    }

    func applicationDidResignActive(_ notification: Notification) {
        logLifecycle("applicationDidResignActive")
    }

    func applicationWillBecomeActive(_ notification: Notification) {
        logLifecycle("applicationWillBecomeActive")
    }

    func applicationWillResignActive(_ notification: Notification) {
        logLifecycle("applicationWillResignActive")
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        logLifecycle("applicationShouldHandleReopen hasVisibleWindows=\(flag)")
        return true
    }
}

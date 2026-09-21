import Cocoa
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let renderer = MenuItemRenderer()

    private let statusItem: NSStatusItem
    let menu: NSMenu
    private let appState: SolixAppState
    private var deviceItems: [NSMenuItem] = []
    private var errorItem: NSMenuItem?
    private var cancellables: Set<AnyCancellable> = []

    var onAccountSettings: (() -> Void)?
    var onAbout: (() -> Void)?
    var onQuit: (() -> Void)?

    init(appState: SolixAppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.menu = NSMenu()
        super.init()
        configureStatusItem()
        configureMenu()
        configureApplicationMenu()
        bindState()
    }

    private func configureStatusItem() {
        statusItem.isVisible = true
        if let button = statusItem.button {
            let image = statusImage(isAuthenticated: appState.isAuthenticated)
            button.image = image
            button.title = image == nil ? AppLocalization.text("about.title") : ""
            if image == nil {
                button.imagePosition = .noImage
                AppLogger.log("Status bar image unavailable; showing title only.")
            } else {
                button.imagePosition = .imageOnly
            }
            updateStatusButton()
        } else {
            AppLogger.log("Status bar button is nil; status item may not be visible.")
        }
        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.autoenablesItems = false
        updateDeviceItems()
        addFixedItems()
    }

    private func configureApplicationMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        for (title, action, key) in [
            ("menu.about", #selector(handleAbout), ""),
            ("menu.account_settings", #selector(handleAccountSettings), ","),
            ("menu.quit", #selector(handleQuit), "q"),
        ] {
            if title == "menu.quit" { appMenu.addItem(.separator()) }
            let item = NSMenuItem(title: AppLocalization.text(title), action: action, keyEquivalent: key)
            item.target = self
            appMenu.addItem(item)
        }
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)
        let fileItem = NSMenuItem(title: AppLocalization.text("menu.file"), action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: AppLocalization.text("menu.file"))
        fileMenu.addItem(withTitle: AppLocalization.text("menu.close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)
        NSApp.mainMenu = mainMenu
    }

    private func bindState() {
        appState.$devices
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDeviceItems()
            }
            .store(in: &cancellables)

        appState.$isAuthenticated
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateStatusButton()
                self.updateDeviceItems()
            }
            .store(in: &cancellables)

        appState.$lastErrorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDeviceItems()
            }
            .store(in: &cancellables)
    }

    private func updateDeviceItems() {
        AppLogger.log(
            "StatusBarController: updateDeviceItems start devices=\(appState.devices.count) hasError=\((appState.lastErrorMessage?.isEmpty == false)) menuItems=\(menu.items.count)"
        )
        for item in deviceItems {
            menu.removeItem(item)
        }
        deviceItems.removeAll()

        if let errorItem {
            menu.removeItem(errorItem)
            self.errorItem = nil
        }

        let devices = appState.sortedDevices

        if devices.isEmpty {
            if appState.lastErrorMessage == nil || appState.lastErrorMessage?.isEmpty == true {
                let item = NSMenuItem(
                    title: AppLocalization.text(appState.isAuthenticated ? "menu.no_devices" : "menu.sign_in_required"), action: nil, keyEquivalent: "")
                item.isEnabled = false
                deviceItems.append(item)
            }
        } else {
            for device in devices {
                let header = NSMenuItem.sectionHeader(title: device.name)
                header.toolTip = device.name
                let item = NSMenuItem(title: renderer.summary(for: device), action: nil, keyEquivalent: "")
                item.isEnabled = false
                item.attributedTitle = renderer.attributedTitle(for: device)
                item.setAccessibilityLabel("\(device.name), \(renderer.summary(for: device))")
                deviceItems.append(contentsOf: [header, item])
            }
        }

        if let message = appState.lastErrorMessage, !message.isEmpty {
            let item = NSMenuItem(title: AppLocalization.text("menu.connection_error"), action: #selector(handleErrorDetails), keyEquivalent: "")
            item.target = self
            item.toolTip = message
            item.setAccessibilityHelp(message)
            item.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: nil)
            item.isEnabled = true
            menu.insertItem(item, at: 0)
            errorItem = item
        }

        let offset = errorItem == nil ? 0 : 1
        for (index, item) in deviceItems.enumerated() {
            menu.insertItem(item, at: index + offset)
        }
        AppLogger.log(
            "StatusBarController: updateDeviceItems done insertedDevices=\(deviceItems.count) errorVisible=\(errorItem != nil) totalMenuItems=\(menu.items.count)"
        )
    }

    private func addFixedItems() {
        if !menu.items.contains(where: { $0.isSeparatorItem }) {
            menu.addItem(NSMenuItem.separator())
        }

        let accountItem = NSMenuItem(
            title: AppLocalization.text("menu.account_settings"),
            action: #selector(handleAccountSettings),
            keyEquivalent: ","
        )
        accountItem.target = self
        menu.addItem(accountItem)

        let aboutItem = NSMenuItem(
            title: AppLocalization.text("menu.about"),
            action: #selector(handleAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: AppLocalization.text("menu.quit"),
            action: #selector(handleQuit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        button.image = statusImage(isAuthenticated: appState.isAuthenticated)
        let state = AppLocalization.text(appState.isAuthenticated ? "menu.signed_in" : "menu.sign_in_required")
        let description = "PowerBankMenu — \(state)"
        button.toolTip = description
        button.setAccessibilityLabel(description)
    }

    private func statusImage(isAuthenticated: Bool) -> NSImage? {
        let name = isAuthenticated ? "bolt.circle" : "exclamationmark.circle"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }

    @objc private func handleErrorDetails() {
        guard let message = appState.lastErrorMessage, !message.isEmpty else { return }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = AppLocalization.text("menu.connection_error")
        alert.informativeText = message
        alert.addButton(withTitle: AppLocalization.text("common.close"))
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func handleAccountSettings() {
        if let onAccountSettings {
            onAccountSettings()
        }
    }

    @objc private func handleAbout() {
        if let onAbout {
            onAbout()
        } else {
            NSApp.orderFrontStandardAboutPanel(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func handleQuit() {
        AppLogger.log("StatusBarController: Quit menu selected")
        if let onQuit {
            AppLogger.log("StatusBarController: forwarding quit action to app delegate")
            onQuit()
        } else {
            AppLogger.log("StatusBarController: terminating app directly from status bar")
            NSApp.terminate(nil)
        }
    }

}

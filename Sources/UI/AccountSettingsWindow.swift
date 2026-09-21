import Cocoa

@MainActor
final class AccountSettingsWindowController: NSWindowController, NSWindowDelegate {
    struct Configuration {
        var title: String = AppLocalization.text("settings.title")
        var minSize: NSSize = NSSize(width: 560, height: 460)
    }

    private let configuration: Configuration
    private let settingsViewController: AccountSettingsViewController
    private let onClose: (() -> Void)?

    init(
        credentials: SolixCredentials?,
        configuration: Configuration = Configuration(),
        onVerify: ((SolixCredentials) async -> Result<Void, Error>)? = nil,
        onCancel: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.configuration = configuration
        self.onClose = onClose
        self.settingsViewController = AccountSettingsViewController(
            credentials: credentials,
            onVerify: onVerify,
            onCancel: onCancel
        )

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: configuration.minSize),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = configuration.title
        window.isReleasedWhenClosed = false
        window.center()
        window.contentViewController = settingsViewController
        window.contentMinSize = configuration.minSize
        window.setContentSize(configuration.minSize)
        window.collectionBehavior = [.fullScreenNone]

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func present() {
        guard let window else { return }
        installEditMenuIfNeeded()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        !settingsViewController.isVerifying
    }

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }

    private func installEditMenuIfNeeded() {
        let app = NSApplication.shared
        if app.mainMenu == nil {
            app.mainMenu = NSMenu()
        }
        guard let mainMenu = app.mainMenu else { return }
        if mainMenu.item(withTitle: AppLocalization.text("menu.edit")) != nil {
            return
        }

        let editMenuItem = NSMenuItem(title: AppLocalization.text("menu.edit"), action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: AppLocalization.text("menu.edit"))
        editMenu.addItem(
            NSMenuItem(title: AppLocalization.text("menu.cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(
            NSMenuItem(title: AppLocalization.text("menu.copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(
            NSMenuItem(title: AppLocalization.text("menu.paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(
            NSMenuItem(
                title: AppLocalization.text("menu.select_all"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)
    }
}

@MainActor
private final class AccountSettingsViewController: NSViewController {
    private let onVerify: ((SolixCredentials) async -> Result<Void, Error>)?
    private let onCancel: (() -> Void)?

    private let emailField = NSTextField()
    private let passwordField = NSSecureTextField()
    private let countryField = NSTextField()
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    private let debugLogCheckbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)

    private let statusLabel = NSTextField(wrappingLabelWithString: "")
    private let statusIcon = NSImageView()
    private var contentStack: NSStackView!
    private(set) var isVerifying = false
    private let progressIndicator = NSProgressIndicator()

    private let verifyButton = NSButton()
    private let cancelButton = NSButton()

    init(
        credentials: SolixCredentials?,
        onVerify: ((SolixCredentials) async -> Result<Void, Error>)?,
        onCancel: (() -> Void)?
    ) {
        self.onVerify = onVerify
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)

        if let credentials {
            emailField.stringValue = credentials.email
            passwordField.stringValue = credentials.password
            countryField.stringValue = credentials.countryId
        } else {
            countryField.stringValue = "EU"
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        let view = NSView()
        configureFields()
        configureLaunchAtLoginToggle()
        configureDebugToggle()
        configureButtons()

        let general = section([
            heading("settings.general_section"),
            launchAtLoginCheckbox,
            debugLogCheckbox,
            helpLabel("settings.general_help"),
        ])
        let labels = ["settings.email", "settings.password", "settings.country"].map {
            NSTextField(labelWithString: AppLocalization.text($0))
        }
        let fields = [emailField, passwordField, countryField]
        for (label, field) in zip(labels, fields) {
            label.alignment = .right
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            field.setAccessibilityLabel(label.stringValue)
            field.setAccessibilityTitleUIElement(label)
        }
        let grid = NSGridView(views: zip(labels, fields).map { [$0, $1] })
        grid.columnSpacing = 12
        grid.rowSpacing = 12
        grid.column(at: 0).xPlacement = .trailing
        grid.column(at: 1).xPlacement = .fill
        grid.yPlacement = .center
        let account = section([
            heading("settings.account_section"), grid, helpLabel("settings.country_help"),
        ])

        let separator = NSBox()
        separator.boxType = .separator
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        statusIcon.imageScaling = .scaleProportionallyDown
        statusIcon.isHidden = true
        statusIcon.setAccessibilityElement(false)
        progressIndicator.controlSize = .small
        progressIndicator.style = .spinning
        progressIndicator.isDisplayedWhenStopped = false
        progressIndicator.isHidden = true
        progressIndicator.setAccessibilityLabel(AppLocalization.text("settings.status.verifying"))
        let statusRow = NSStackView(views: [progressIndicator, statusIcon, statusLabel])
        statusRow.orientation = .horizontal
        statusRow.alignment = .top
        statusRow.spacing = 8

        let buttonRow = NSStackView(views: [NSView(), cancelButton, verifyButton])
        buttonRow.orientation = .horizontal
        buttonRow.spacing = 8
        contentStack = section([general, separator, account, statusRow, buttonRow])
        contentStack.spacing = 18
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            contentStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 24),
            contentStack.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -24),
            emailField.widthAnchor.constraint(greaterThanOrEqualToConstant: 280),
            statusRow.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            statusIcon.widthAnchor.constraint(equalToConstant: 16),
            statusIcon.heightAnchor.constraint(equalToConstant: 16),
            progressIndicator.widthAnchor.constraint(equalToConstant: 16),
            progressIndicator.heightAnchor.constraint(equalToConstant: 16),
        ])
        self.view = view
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.initialFirstResponder = emailField
        view.window?.makeFirstResponder(emailField)
        fitContentIfNeeded()
    }

    private func section(_ views: [NSView]) -> NSStackView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        for child in views {
            child.translatesAutoresizingMaskIntoConstraints = false
            child.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return stack
    }

    private func heading(_ key: String) -> NSTextField {
        let label = NSTextField(labelWithString: AppLocalization.text(key))
        label.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        return label
    }

    private func helpLabel(_ key: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: AppLocalization.text(key))
        label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        label.textColor = .secondaryLabelColor
        return label
    }

    private func fitContentIfNeeded() {
        guard let window = view.window else { return }
        view.layoutSubtreeIfNeeded()
        let requiredHeight = max(460, contentStack.fittingSize.height + 48)
        window.contentMinSize = NSSize(width: 560, height: requiredHeight)
        if view.bounds.height < requiredHeight {
            window.setContentSize(NSSize(width: view.bounds.width, height: requiredHeight))
        }
    }

    private func configureFields() {
        [emailField, passwordField, countryField].forEach { field in
            field.isEditable = true
            field.isSelectable = true
            field.isEnabled = true
            field.refusesFirstResponder = false
            field.font = .systemFont(ofSize: NSFont.systemFontSize)
            field.lineBreakMode = .byTruncatingTail
        }
    }

    private func configureLaunchAtLoginToggle() {
        launchAtLoginCheckbox.title = AppLocalization.text("settings.launch_at_login")
        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(handleLaunchAtLoginToggle)
        launchAtLoginCheckbox.state = AppSettings.shared.isLaunchAtLoginEnabled ? .on : .off
    }

    private func configureDebugToggle() {
        debugLogCheckbox.title = AppLocalization.text("settings.debug_log")
        debugLogCheckbox.target = self
        debugLogCheckbox.action = #selector(handleDebugLogToggle)
        debugLogCheckbox.state = AppSettings.shared.isDebugLogEnabled ? .on : .off
    }

    private func configureButtons() {
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        verifyButton.bezelStyle = .rounded
        cancelButton.title = AppLocalization.text("settings.cancel")
        cancelButton.target = self
        cancelButton.action = #selector(handleCancel)

        verifyButton.title = AppLocalization.text("settings.save")
        verifyButton.target = self
        verifyButton.action = #selector(handleVerify)
        verifyButton.keyEquivalent = "\r"
    }

    private func currentCredentials() -> SolixCredentials? {
        let email = emailField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordField.stringValue
        let country = countryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !email.isEmpty, !password.isEmpty, !country.isEmpty else {
            showError(AppLocalization.text("settings.error.missing_fields"))
            let missingField = email.isEmpty ? emailField : (password.isEmpty ? passwordField : countryField)
            view.window?.makeFirstResponder(missingField)
            return nil
        }

        return SolixCredentials(
            email: email,
            password: password,
            countryId: country.uppercased()
        )
    }

    @objc private func handleVerify() {
        guard !isVerifying else { return }
        guard let credentials = currentCredentials() else { return }
        guard let onVerify else {
            showError(AppLocalization.text("settings.error.auth_failed"))
            return
        }

        setLoading(true, message: AppLocalization.text("settings.status.verifying"))
        Task {
            let result = await onVerify(credentials)
            setLoading(false, message: nil)
            switch result {
            case .success:
                showStatus(AppLocalization.text("settings.status.success"))
                closeWindow()
            case .failure(let error):
                showError(
                    error.localizedDescription.isEmpty
                        ? AppLocalization.text("settings.status.failure")
                        : error.localizedDescription
                )
                view.window?.makeFirstResponder(emailField)
            }
        }
    }

    @objc private func handleCancel() {
        guard !isVerifying else { return }
        onCancel?()
        closeWindow()
    }

    @objc private func handleDebugLogToggle() {
        AppSettings.shared.isDebugLogEnabled = debugLogCheckbox.state == .on
    }

    @objc private func handleLaunchAtLoginToggle() {
        let enabled = launchAtLoginCheckbox.state == .on
        do {
            try AppSettings.shared.setLaunchAtLoginEnabled(enabled)
            launchAtLoginCheckbox.state = AppSettings.shared.isLaunchAtLoginEnabled ? .on : .off
            hideStatus()
        } catch {
            launchAtLoginCheckbox.state = AppSettings.shared.isLaunchAtLoginEnabled ? .on : .off
            showError(AppLocalization.text("settings.error.launch_at_login_failed"))
        }
    }

    private func closeWindow() {
        if let window = view.window {
            window.performClose(nil)
        } else {
            dismiss(nil)
        }
    }

    private func setLoading(_ loading: Bool, message: String?) {
        isVerifying = loading
        [emailField, passwordField, countryField].forEach { $0.isEnabled = !loading }
        [verifyButton, cancelButton, launchAtLoginCheckbox, debugLogCheckbox].forEach {
            $0.isEnabled = !loading
        }
        view.window?.standardWindowButton(.closeButton)?.isEnabled = !loading
        if loading { statusIcon.isHidden = true }
        progressIndicator.isHidden = !loading
        if loading {
            progressIndicator.startAnimation(nil)
        } else {
            progressIndicator.stopAnimation(nil)
        }
        if let message {
            statusLabel.stringValue = message
            statusLabel.textColor = .secondaryLabelColor
            statusLabel.isHidden = false
        }
    }

    private func showError(_ message: String) {
        statusLabel.stringValue = message
        statusIcon.image = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil)
        statusIcon.contentTintColor = .systemOrange
        statusIcon.isHidden = false
        statusLabel.textColor = .labelColor
        statusLabel.isHidden = false
        fitContentIfNeeded()
        NSAccessibility.post(element: statusLabel, notification: .announcementRequested, userInfo: [
            .announcement: message,
            .priority: NSAccessibilityPriorityLevel.high.rawValue,
        ])
    }

    private func showStatus(_ message: String) {
        statusLabel.stringValue = message
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.isHidden = false
    }

    private func hideStatus() {
        statusLabel.stringValue = ""
        statusIcon.isHidden = true
    }
}

import Cocoa

@MainActor
final class AboutWindowController: NSWindowController, NSWindowDelegate {
    static let shared = AboutWindowController()

    private let titleLabel = NSTextField(labelWithString: AppLocalization.text("about.title"))
    private let versionLabel = NSTextField(
        labelWithString: AppLocalization.text("about.version.placeholder")
    )
    private let detailLabel = NSTextField(labelWithString: AppLocalization.text("about.subtitle"))
    private let iconView = NSImageView()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppLocalization.text("menu.about")
        window.center()
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor

        super.init(window: window)
        window.delegate = self

        configureContent()
        refreshVersionText()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func show() {
        refreshVersionText()
        guard let window else { return }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureContent() {
        guard let contentView = window?.contentView else { return }
        contentView.wantsLayer = true

        iconView.setAccessibilityElement(false)
        iconView.image = NSApp.applicationIconImage
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .center

        versionLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        versionLabel.textColor = .secondaryLabelColor
        versionLabel.alignment = .center

        detailLabel.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.alignment = .center
        detailLabel.maximumNumberOfLines = 0

        let stack = NSStackView(views: [iconView, titleLabel, versionLabel, detailLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 72),
            iconView.heightAnchor.constraint(equalToConstant: 72),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stack.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
        ])
    }

    private func refreshVersionText() {
        let bundle = Bundle.main
        let shortVersion =
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        let versionString: String
        if let shortVersion, let buildVersion {
            versionString = AppLocalization.text(
                "about.version.format",
                shortVersion,
                buildVersion
            )
        } else if let shortVersion {
            versionString = AppLocalization.text(
                "about.version.short_format",
                shortVersion
            )
        } else {
            versionString = AppLocalization.text("about.version.placeholder")
        }

        versionLabel.stringValue = versionString
    }

    func windowWillClose(_ notification: Notification) {
        // Keep instance alive for reuse.
    }
}

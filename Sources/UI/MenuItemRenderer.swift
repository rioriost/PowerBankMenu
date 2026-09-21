import Cocoa

/// Shared formatting for the informational rows in the native status menu.
@MainActor
struct MenuItemRenderer {
    func summary(for device: SolixAppState.Device) -> String {
        let battery = device.batteryPercent.map { "\($0)%" } ?? "—"
        let output = device.outputWatts.map { "\($0) W" } ?? "—"
        let input = device.inputWatts.map { "\($0) W" } ?? "—"
        var text = AppLocalization.text("menu.device_summary", battery, output, input)
        if let percent = device.batteryPercent, percent < 10 {
            text += "  ·  " + AppLocalization.text("menu.low_battery")
        }
        return text
    }

    func attributedTitle(for device: SolixAppState.Device) -> NSAttributedString {
        NSAttributedString(string: summary(for: device), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ])
    }
}

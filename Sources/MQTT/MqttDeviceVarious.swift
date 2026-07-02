//
//  MqttDeviceVarious.swift
//  PowerBankMenu
//
//  Simplified MQTT device class for various devices (e.g., smart plug).
//

import Foundation

final class SolixMqttDeviceVarious: SolixMqttDevice {
    // MARK: - Supported Models / Features

    static let models: Set<String> = [
        "A17X8"  // Smartplug
    ]

    static let features: [String: Set<String>] = [
        SolixMqttCommands.statusRequest: models,
        SolixMqttCommands.realtimeTrigger: models,
        SolixMqttCommands.acOutputSwitch: models,
            // Complex multi-parameter commands intentionally omitted:
            // SolixMqttCommands.plugSchedule
            // SolixMqttCommands.plugDelayedToggle
    ]

    // MARK: - Init

    init(api: SolixApi, deviceSn: String) {
        super.init(api: api, deviceSn: deviceSn, models: Self.models, features: Self.features)
    }

    // MARK: - Capability

    override func supports(command: String) -> Bool {
        guard let model = device["device_pn"] as? String else { return false }
        return Self.features[command]?.contains(model) == true
    }

    // MARK: - Controls

    /// Control AC output power via MQTT.
    /// - Parameters:
    ///   - enabled: True to enable AC output, false to disable.
    ///   - toFile: If true, skip publish and only log the command (compat).
    /// - Returns: Updated state if successful, otherwise nil.
    func setAcOutput(
        enabled: Bool? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let enabled else { return nil }
        guard supports(command: SolixMqttCommands.acOutputSwitch) else { return nil }

        let parameters: [String: Any] = [
            "set_ac_output_switch": enabled ? "on" : "off"
        ]

        let result = await sendCommand(
            SolixMqttCommands.acOutputSwitch,
            parameters: parameters,
            description: "AC output -> \(enabled ? "on" : "off")",
            toFile: toFile
        )

        return result == nil ? nil : ["ac_output_power_switch": enabled ? 1 : 0]
    }
}

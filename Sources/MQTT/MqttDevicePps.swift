//
//  MqttDevicePps.swift
//  PowerBankMenu
//
//  Simplified PPS MQTT device class
//

import Foundation

final class SolixMqttDevicePps: SolixMqttDevice {
    // Supported models
    static let models: Set<String> = [
        "A1722", "A1723", "A1726", "A1728",
        "A1761", "A1763",
        "A1780", "A1780P",
        "A1790", "A1790P",
    ]

    // Supported commands per model
    static let features: [String: Set<String>] = [
        SolixMqttCommands.realtimeTrigger: models,
        SolixMqttCommands.tempUnitSwitch: models,
        SolixMqttCommands.deviceMaxLoad: models,
        SolixMqttCommands.deviceTimeoutMinutes: models,
        SolixMqttCommands.acChargeSwitch: models,
        SolixMqttCommands.acChargeLimit: models,
        SolixMqttCommands.acOutputSwitch: models,
        SolixMqttCommands.acFastChargeSwitch: models,
        SolixMqttCommands.acOutputModeSelect: models,
        SolixMqttCommands.acOutputTimeoutSeconds: models,
        SolixMqttCommands.dcOutputSwitch: models,
        SolixMqttCommands.dc12vOutputModeSelect: models,
        SolixMqttCommands.dcOutputTimeoutSeconds: models,
        SolixMqttCommands.displaySwitch: models,
        SolixMqttCommands.displayModeSelect: models,
        SolixMqttCommands.displayTimeoutSeconds: models,
        SolixMqttCommands.lightSwitch: models,
        SolixMqttCommands.lightModeSelect: models,
        SolixMqttCommands.portMemorySwitch: models,
        SolixMqttCommands.socLimits: models,
    ]

    init(api: SolixApi, deviceSn: String) {
        super.init(api: api, deviceSn: deviceSn, models: Self.models, features: Self.features)
    }

    // MARK: - PPS Commands

    func setAcOutput(
        enabled: Bool? = nil,
        mode: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        var response: [String: Any] = [:]

        if let enabled {
            guard supports(command: SolixMqttCommands.acOutputSwitch) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.acOutputSwitch,
                parameters: ["set_ac_output_switch": enabled ? "on" : "off"],
                description: "AC output -> \(enabled ? "on" : "off")",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["ac_output_power_switch"] = enabled ? 1 : 0
        }

        if let mode {
            guard supports(command: SolixMqttCommands.acOutputModeSelect) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.acOutputModeSelect,
                parameters: ["set_ac_output_mode": mode],
                description: "AC output mode -> \(mode)",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["ac_output_mode"] = mode
        }

        return response.isEmpty ? nil : response
    }

    func setDcOutput(
        enabled: Bool? = nil,
        mode: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        var response: [String: Any] = [:]

        if let enabled {
            guard supports(command: SolixMqttCommands.dcOutputSwitch) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.dcOutputSwitch,
                parameters: ["set_dc_output_switch": enabled ? "on" : "off"],
                description: "DC output -> \(enabled ? "on" : "off")",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["dc_output_power_switch"] = enabled ? 1 : 0
        }

        if let mode {
            guard supports(command: SolixMqttCommands.dc12vOutputModeSelect) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.dc12vOutputModeSelect,
                parameters: ["set_dc_12v_output_mode": mode],
                description: "DC 12V output mode -> \(mode)",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["dc_12v_output_mode"] = mode
        }

        return response.isEmpty ? nil : response
    }

    func setDisplay(
        enabled: Bool? = nil,
        mode: String? = nil,
        timeoutSeconds: Int? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        var response: [String: Any] = [:]

        if let enabled {
            guard supports(command: SolixMqttCommands.displaySwitch) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.displaySwitch,
                parameters: ["set_display_switch": enabled ? "on" : "off"],
                description: "Display -> \(enabled ? "on" : "off")",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["display_switch"] = enabled ? 1 : 0
        }

        if let mode {
            guard supports(command: SolixMqttCommands.displayModeSelect) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.displayModeSelect,
                parameters: ["set_display_mode": mode],
                description: "Display mode -> \(mode)",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["display_mode"] = mode
        }

        if let timeoutSeconds {
            guard supports(command: SolixMqttCommands.displayTimeoutSeconds) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.displayTimeoutSeconds,
                parameters: ["set_display_timeout_sec": timeoutSeconds],
                description: "Display timeout -> \(timeoutSeconds)s",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["display_timeout_seconds"] = timeoutSeconds
        }

        return response.isEmpty ? nil : response
    }

    func setBackupCharge(
        enabled: Bool? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let enabled else { return nil }
        guard supports(command: SolixMqttCommands.acChargeSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.acChargeSwitch,
            parameters: ["set_ac_charge_switch": enabled ? "on" : "off"],
            description: "Backup charge -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["backup_charge_switch": enabled ? 1 : 0]
    }

    func setTempUnit(
        unit: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let unit else { return nil }
        guard supports(command: SolixMqttCommands.tempUnitSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.tempUnitSwitch,
            parameters: ["set_temp_unit_fahrenheit": unit],
            description: "Temp unit -> \(unit)",
            toFile: toFile
        )
        return result == nil ? nil : ["temp_unit_fahrenheit": unit]
    }

    func setLight(
        mode: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let mode else { return nil }
        guard supports(command: SolixMqttCommands.lightModeSelect) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.lightModeSelect,
            parameters: ["set_light_mode": mode],
            description: "Light mode -> \(mode)",
            toFile: toFile
        )
        return result == nil ? nil : ["light_mode": mode]
    }

    func setDeviceTimeout(
        timeoutMinutes: Int? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let timeoutMinutes else { return nil }
        guard supports(command: SolixMqttCommands.deviceTimeoutMinutes) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.deviceTimeoutMinutes,
            parameters: ["set_device_timeout_min": timeoutMinutes],
            description: "Device timeout -> \(timeoutMinutes) min",
            toFile: toFile
        )
        return result == nil ? nil : ["device_timeout_minutes": timeoutMinutes]
    }

    func setMaxLoad(
        maxWatts: Int? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let maxWatts else { return nil }
        guard supports(command: SolixMqttCommands.deviceMaxLoad) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.deviceMaxLoad,
            parameters: ["set_device_max_load": maxWatts],
            description: "Max load -> \(maxWatts)W",
            toFile: toFile
        )
        return result == nil ? nil : ["max_load": maxWatts]
    }

    func setChargeLimit(
        maxWatts: Int? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let maxWatts else { return nil }
        guard supports(command: SolixMqttCommands.acChargeLimit) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.acChargeLimit,
            parameters: ["set_ac_input_limit": maxWatts],
            description: "AC charge limit -> \(maxWatts)W",
            toFile: toFile
        )
        return result == nil ? nil : ["ac_input_limit": maxWatts]
    }

    func setFastCharging(
        enabled: Bool? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard let enabled else { return nil }
        guard supports(command: SolixMqttCommands.acFastChargeSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.acFastChargeSwitch,
            parameters: ["set_ac_fast_charge_switch": enabled ? "on" : "off"],
            description: "Fast charging -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["fast_charge_switch": enabled ? 1 : 0]
    }

    func setPortMemory(
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.portMemorySwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.portMemorySwitch,
            parameters: ["set_port_memory_switch": enabled ? "on" : "off"],
            description: "Port memory -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["port_memory_switch": enabled ? 1 : 0]
    }
}

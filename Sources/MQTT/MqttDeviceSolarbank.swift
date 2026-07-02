//
//  MqttDeviceSolarbank.swift
//  PowerBankMenu
//
//  Simplified MQTT device definition for Anker Solix Solarbank devices.
//  Swift port of anker-solix-api/api/mqtt_solarbank.py (model/feature sets only)
//

import Foundation

final class SolixMqttDeviceSolarbank: SolixMqttDevice {
    // MARK: - Supported Models

    static let models: Set<String> = [
        "A17C0",  // Solarbank 1 E1600
        "A17C1",  // Solarbank 2 E1600 Pro
        "A17C2",  // Solarbank 2 E1600 AC
        "A17C3",  // Solarbank 2 E1600 Plus
        "A17C5",  // Solarbank 3 E2700 Pro
        "AE100",  // Power Dock
    ]

    // MARK: - Supported Features

    static let features: [String: Set<String>] = [
        SolixMqttCommands.statusRequest: models,
        SolixMqttCommands.realtimeTrigger: models,
        SolixMqttCommands.tempUnitSwitch: models,
        // Min SOC differs since SB3
        SolixMqttCommands.sbPowerCutoffSelect: ["A17C0", "A17C1", "A17C2", "A17C3"],
        SolixMqttCommands.sbMinSocSelect: ["A17C5", "AE100"],
        // Commands since SB2
        SolixMqttCommands.sbAcSocketSwitch: models,
        SolixMqttCommands.sbLightSwitch: models,
        SolixMqttCommands.sbLightModeSelect: models,
        SolixMqttCommands.sbMaxLoad: models,
        SolixMqttCommands.sbMaxLoadParallel: models,
        // Commands since SB2 AC / SB3
        SolixMqttCommands.sbDisableGridExportSwitch: models,
        SolixMqttCommands.sbDeviceTimeout: models,
        SolixMqttCommands.sbAcInputLimit: models,
        SolixMqttCommands.sbPvLimitSelect: models,
    ]

    // MARK: - Init

    init(api: SolixApi, deviceSn: String) {
        super.init(api: api, deviceSn: deviceSn, models: Self.models, features: Self.features)
    }

    // MARK: - Solarbank Commands

    func setTempUnit(
        unit: String,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.tempUnitSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.tempUnitSwitch,
            parameters: ["set_temp_unit_fahrenheit": unit],
            description: "Temp unit -> \(unit)",
            toFile: toFile
        )
        return result == nil ? nil : ["temp_unit_fahrenheit": unit]
    }

    func setMinSoc(
        limit: Int,
        toFile: Bool = false
    ) async -> [String: Any]? {
        let cmd =
            supports(command: SolixMqttCommands.sbPowerCutoffSelect)
            ? SolixMqttCommands.sbPowerCutoffSelect
            : SolixMqttCommands.sbMinSocSelect

        guard supports(command: cmd) else { return nil }

        let key =
            cmd == SolixMqttCommands.sbPowerCutoffSelect
            ? "set_output_cutoff_data"
            : "set_min_soc"

        let result = await sendCommand(
            cmd,
            parameters: [key: limit],
            description: "Min SOC -> \(limit)%",
            toFile: toFile
        )
        return result == nil ? nil : ["power_cutoff": limit]
    }

    func setAcSocket(
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.sbAcSocketSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.sbAcSocketSwitch,
            parameters: ["set_ac_socket_switch": enabled ? "on" : "off"],
            description: "AC socket -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["ac_socket_switch": enabled ? 1 : 0]
    }

    func setLight(
        enabled: Bool? = nil,
        mode: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        var response: [String: Any] = [:]

        if let enabled {
            guard supports(command: SolixMqttCommands.sbLightSwitch) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.sbLightSwitch,
                parameters: ["set_light_off_switch": enabled ? "off" : "on"],
                description: "Light switch -> \(enabled ? "on" : "off")",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["light_off_switch"] = enabled ? 0 : 1
        }

        if let mode {
            guard supports(command: SolixMqttCommands.sbLightModeSelect) else { return nil }
            let result = await sendCommand(
                SolixMqttCommands.sbLightModeSelect,
                parameters: ["set_light_mode": mode],
                description: "Light mode -> \(mode)",
                toFile: toFile
            )
            guard result != nil else { return nil }
            response["light_mode"] = mode
        }

        return response.isEmpty ? nil : response
    }

    func setMaxLoad(
        maxWatts: Int,
        type: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.sbMaxLoad) else { return nil }

        var params: [String: Any] = ["set_max_load": maxWatts]
        if let type {
            params["set_max_load_type"] = type
        }

        let result = await sendCommand(
            SolixMqttCommands.sbMaxLoad,
            parameters: params,
            description: "Max load -> \(maxWatts)W",
            toFile: toFile
        )
        return result == nil ? nil : ["max_load": maxWatts]
    }

    func setDisableGridExport(
        enabled: Bool,
        limit: Int? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.sbDisableGridExportSwitch) else { return nil }

        var params: [String: Any] = [
            "set_disable_grid_export_switch": enabled ? "on" : "off"
        ]
        if let limit {
            params["set_grid_export_limit"] = limit
        }

        let result = await sendCommand(
            SolixMqttCommands.sbDisableGridExportSwitch,
            parameters: params,
            description: "Grid export -> \(enabled ? "disabled" : "enabled")",
            toFile: toFile
        )
        return result == nil ? nil : ["grid_export_disabled": enabled ? 1 : 0]
    }

    func setDeviceTimeout(
        timeoutMinutes: Int,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.sbDeviceTimeout) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.sbDeviceTimeout,
            parameters: ["set_device_timeout_min": timeoutMinutes],
            description: "Device timeout -> \(timeoutMinutes) min",
            toFile: toFile
        )
        return result == nil ? nil : ["device_timeout_minutes": timeoutMinutes]
    }

    func setAcInputLimit(
        limitWatts: Int,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.sbAcInputLimit) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.sbAcInputLimit,
            parameters: ["set_ac_input_limit": limitWatts],
            description: "AC input limit -> \(limitWatts)W",
            toFile: toFile
        )
        return result == nil ? nil : ["ac_input_limit": limitWatts]
    }

    func setPvLimit(
        limitWatts: Int,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.sbPvLimitSelect) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.sbPvLimitSelect,
            parameters: ["set_sb_pv_limit_select": limitWatts],
            description: "PV limit -> \(limitWatts)W",
            toFile: toFile
        )
        return result == nil ? nil : ["pv_limit": limitWatts]
    }
}

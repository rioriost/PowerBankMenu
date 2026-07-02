//
//  MqttDeviceCharger.swift
//  PowerBankMenu
//
//  Simplified Charger MQTT device class.
//  Swift port of anker-solix-api/api/mqtt_charger.py
//

import Foundation

final class SolixMqttDeviceCharger: SolixMqttDevice {
    // MARK: - Supported Models

    static let models: Set<String> = [
        "A2345",  // 250W Prime Charger
        "A5191",  // V1 EV Charger
    ]

    // MARK: - Supported Features

    static let features: [String: Set<String>] = [
        SolixMqttCommands.statusRequest: models,
        SolixMqttCommands.realtimeTrigger: models,
        SolixMqttCommands.usbc1PortSwitch: models,
        SolixMqttCommands.usbc2PortSwitch: models,
        SolixMqttCommands.usbc3PortSwitch: models,
        SolixMqttCommands.usbc4PortSwitch: models,
        SolixMqttCommands.usbaPortSwitch: models,
        SolixMqttCommands.evAutoStartSwitch: models,
        SolixMqttCommands.evAutoChargeRestartSwitch: models,
        SolixMqttCommands.evRandomDelaySwitch: models,
        SolixMqttCommands.evMaxChargeCurrent: models,
        SolixMqttCommands.evLoadBalancing: models,
        SolixMqttCommands.evSolarCharging: models,
        SolixMqttCommands.mainBreakerLimit: models,
        SolixMqttCommands.evChargerScheduleSettings: models,
        SolixMqttCommands.evChargerScheduleTimes: models,
        SolixMqttCommands.evChargerModeSelect: models,
        SolixMqttCommands.devicePowerMode: models,
        SolixMqttCommands.lightBrightness: models,
        SolixMqttCommands.lightOffSchedule: models,
        SolixMqttCommands.smartTouchModeSelect: models,
        SolixMqttCommands.swipeUpModeSelect: models,
        SolixMqttCommands.swipeDownModeSelect: models,
        SolixMqttCommands.modbusSwitch: models,
    ]

    // MARK: - Init

    init(api: SolixApi, deviceSn: String) {
        super.init(api: api, deviceSn: deviceSn, models: Self.models, features: Self.features)
    }

    // MARK: - Charger Commands

    func setUsbPortSwitch(
        port: String,
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        let command: String
        switch port.uppercased() {
        case "C1":
            command = SolixMqttCommands.usbc1PortSwitch
        case "C2":
            command = SolixMqttCommands.usbc2PortSwitch
        case "C3":
            command = SolixMqttCommands.usbc3PortSwitch
        case "C4":
            command = SolixMqttCommands.usbc4PortSwitch
        case "A":
            command = SolixMqttCommands.usbaPortSwitch
        default:
            return nil
        }

        guard supports(command: command) else { return nil }

        let result = await sendCommand(
            command,
            parameters: [
                "set_port_switch_select": port.uppercased(),
                "set_port_switch": enabled ? "on" : "off",
            ],
            description: "USB port \(port.uppercased()) -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["port_switch": enabled ? 1 : 0]
    }

    func setEvAutoStart(
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evAutoStartSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.evAutoStartSwitch,
            parameters: ["set_auto_start_switch": enabled ? "on" : "off"],
            description: "EV auto start -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["auto_start_switch": enabled ? 1 : 0]
    }

    func setEvAutoChargeRestart(
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evAutoChargeRestartSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.evAutoChargeRestartSwitch,
            parameters: ["set_auto_charge_restart_switch": enabled ? "on" : "off"],
            description: "EV auto charge restart -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["auto_charge_restart_switch": enabled ? 1 : 0]
    }

    func setEvRandomDelay(
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evRandomDelaySwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.evRandomDelaySwitch,
            parameters: ["set_random_delay_switch": enabled ? "on" : "off"],
            description: "EV random delay -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["random_delay_switch": enabled ? 1 : 0]
    }

    func setEvMaxChargeCurrent(
        amps: Double,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evMaxChargeCurrent) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.evMaxChargeCurrent,
            parameters: ["set_max_evcharge_current": amps],
            description: "EV max charge current -> \(amps)A",
            toFile: toFile
        )
        return result == nil ? nil : ["max_evcharge_current": amps]
    }

    func setEvChargerMode(
        mode: String,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evChargerModeSelect) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.evChargerModeSelect,
            parameters: ["set_ev_charger_mode": mode],
            description: "EV charger mode -> \(mode)",
            toFile: toFile
        )
        return result == nil ? nil : ["ev_charger_mode": mode]
    }

    func restartDevicePower(
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.devicePowerMode) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.devicePowerMode,
            parameters: ["set_device_power_mode": "restart"],
            description: "Device power -> restart",
            toFile: toFile
        )
        return result == nil ? nil : ["device_power_mode": "restart"]
    }

    func setMainBreakerLimit(
        amps: Int,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.mainBreakerLimit) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.mainBreakerLimit,
            parameters: ["set_main_breaker_limit": amps],
            description: "Main breaker limit -> \(amps)A",
            toFile: toFile
        )
        return result == nil ? nil : ["main_breaker_limit": amps]
    }

    func setLightBrightness(
        percent: Int,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.lightBrightness) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.lightBrightness,
            parameters: ["set_light_brightness": percent],
            description: "Light brightness -> \(percent)%",
            toFile: toFile
        )
        return result == nil ? nil : ["light_brightness": percent]
    }

    func setLightOffSchedule(
        enabled: Bool,
        startTime: String? = nil,
        endTime: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.lightOffSchedule) else { return nil }

        var params: [String: Any] = [
            "set_light_off_schedule_switch": enabled ? "on" : "off"
        ]
        if let startTime { params["set_light_off_start_time"] = startTime }
        if let endTime { params["set_light_off_end_time"] = endTime }

        let result = await sendCommand(
            SolixMqttCommands.lightOffSchedule,
            parameters: params,
            description: "Light off schedule -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["light_off_schedule_switch": enabled ? 1 : 0]
    }

    func setSmartTouchMode(
        mode: String,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.smartTouchModeSelect) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.smartTouchModeSelect,
            parameters: ["set_smart_touch_mode_select": mode],
            description: "Smart touch mode -> \(mode)",
            toFile: toFile
        )
        return result == nil ? nil : ["smart_touch_mode": mode]
    }

    func setSwipeUpMode(
        mode: String,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.swipeUpModeSelect) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.swipeUpModeSelect,
            parameters: ["set_wipe_up_mode_select": mode],
            description: "Swipe up mode -> \(mode)",
            toFile: toFile
        )
        return result == nil ? nil : ["wipe_up_mode": mode]
    }

    func setSwipeDownMode(
        mode: String,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.swipeDownModeSelect) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.swipeDownModeSelect,
            parameters: ["set_wipe_down_mode_select": mode],
            description: "Swipe down mode -> \(mode)",
            toFile: toFile
        )
        return result == nil ? nil : ["wipe_down_mode": mode]
    }

    func setModbusSwitch(
        enabled: Bool,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.modbusSwitch) else { return nil }

        let result = await sendCommand(
            SolixMqttCommands.modbusSwitch,
            parameters: ["set_modbus_switch": enabled ? "on" : "off"],
            description: "Modbus -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["modbus_switch": enabled ? 1 : 0]
    }

    func setEvLoadBalancing(
        enabled: Bool,
        monitorDevice: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evLoadBalancing) else { return nil }

        var params: [String: Any] = [
            "set_load_balance_switch": enabled ? "on" : "off",
            "set_load_balance_setting_d5": enabled ? "on" : "off",
            "set_load_balance_setting_d6": enabled ? "on" : "off",
        ]
        if let monitorDevice { params["set_load_balance_monitor_device"] = monitorDevice }

        let result = await sendCommand(
            SolixMqttCommands.evLoadBalancing,
            parameters: params,
            description: "EV load balancing -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["load_balance_switch": enabled ? 1 : 0]
    }

    func setEvSolarCharging(
        enabled: Bool,
        mode: String? = nil,
        minCurrent: Int? = nil,
        phaseMode: String? = nil,
        autoPhaseSwitch: Bool? = nil,
        monitoringMode: Bool? = nil,
        monitorDevice: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evSolarCharging) else { return nil }

        var params: [String: Any] = [
            "set_solar_evcharge_switch": enabled ? "on" : "off"
        ]
        if let mode { params["set_solar_evcharge_mode"] = mode }
        if let minCurrent { params["set_solar_evcharge_min_current"] = minCurrent }
        if let phaseMode { params["set_phase_operating_mode"] = phaseMode }
        if let autoPhaseSwitch {
            params["set_auto_phase_switch"] = autoPhaseSwitch ? "on" : "off"
        }
        if let monitoringMode {
            params["set_solar_evcharge_monitoring_mode"] = monitoringMode ? "on" : "off"
        }
        if let monitorDevice { params["set_solar_evcharge_monitor_device"] = monitorDevice }

        let result = await sendCommand(
            SolixMqttCommands.evSolarCharging,
            parameters: params,
            description: "EV solar charging -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["solar_evcharge_switch": enabled ? 1 : 0]
    }

    func setEvChargerScheduleSettings(
        enabled: Bool,
        mode: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evChargerScheduleSettings) else { return nil }

        var params: [String: Any] = [
            "set_schedule_switch": enabled ? "on" : "off"
        ]
        if let mode { params["schedule_mode"] = mode }

        let result = await sendCommand(
            SolixMqttCommands.evChargerScheduleSettings,
            parameters: params,
            description: "EV schedule settings -> \(enabled ? "on" : "off")",
            toFile: toFile
        )
        return result == nil ? nil : ["schedule_switch": enabled ? 1 : 0]
    }

    func setEvChargerScheduleTimes(
        weekStart: String? = nil,
        weekEnd: String? = nil,
        weekendStart: String? = nil,
        weekendEnd: String? = nil,
        weekendMode: String? = nil,
        toFile: Bool = false
    ) async -> [String: Any]? {
        guard supports(command: SolixMqttCommands.evChargerScheduleTimes) else { return nil }

        var params: [String: Any] = [:]
        if let weekStart { params["set_week_start_time"] = weekStart }
        if let weekEnd { params["set_week_end_time"] = weekEnd }
        if let weekendStart { params["set_weekend_start_time"] = weekendStart }
        if let weekendEnd { params["set_weekend_end_time"] = weekendEnd }
        if let weekendMode { params["set_weekend_mode"] = weekendMode }

        let result = await sendCommand(
            SolixMqttCommands.evChargerScheduleTimes,
            parameters: params,
            description: "EV schedule times updated",
            toFile: toFile
        )
        return result == nil ? nil : params
    }
}

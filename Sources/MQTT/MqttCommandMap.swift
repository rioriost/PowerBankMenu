//
//  MqttCommandMap.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/mqttcmdmap.py
//

import Foundation

// MARK: - Command Names

struct SolixMqttCommands {
    static let statusRequest = "status_request"
    static let realtimeTrigger = "realtime_trigger"
    static let timerRequest = "timer_request"
    static let tempUnitSwitch = "temp_unit_switch"
    static let deviceMaxLoad = "device_max_load"
    static let deviceTimeoutMinutes = "device_timeout_minutes"
    static let acChargeSwitch = "ac_charge_switch"
    static let acFastChargeSwitch = "ac_fast_charge_switch"
    static let acChargeLimit = "ac_charge_limit"
    static let acOutputSwitch = "ac_output_switch"
    static let acOutputModeSelect = "ac_output_mode_select"
    static let acOutputTimeoutSeconds = "ac_output_timeout_seconds"
    static let dcOutputSwitch = "dc_output_switch"
    static let dc12vOutputModeSelect = "dc_12v_output_mode_select"
    static let dcOutputTimeoutSeconds = "dc_output_timeout_seconds"
    static let displaySwitch = "display_switch"
    static let displayModeSelect = "display_mode_select"
    static let displayTimeoutSeconds = "display_timeout_seconds"
    static let lightSwitch = "light_switch"
    static let lightModeSelect = "light_mode_select"
    static let portMemorySwitch = "port_memory_switch"
    static let usbc1PortSwitch = "usbc_1_port_switch"
    static let usbc2PortSwitch = "usbc_2_port_switch"
    static let usbc3PortSwitch = "usbc_3_port_switch"
    static let usbc4PortSwitch = "usbc_4_port_switch"
    static let usbaPortSwitch = "usba_port_switch"
    static let socLimits = "soc_limits"
    static let sbStatusCheck = "sb_status_check"
    static let sbPowerCutoffSelect = "sb_power_cutoff_select"
    static let sbMinSocSelect = "sb_min_soc_select"
    static let sbInverterTypeSelect = "sb_inverter_type_select"
    static let sbMaxLoad = "sb_max_load"
    static let sbMaxLoadParallel = "sb_max_load_parallel"
    static let sbAcInputLimit = "sb_ac_input_limit"
    static let sbAcSocketSwitch = "sb_ac_socket_switch"
    static let sbPvLimitSelect = "sb_pv_limit_select"
    static let sbLightSwitch = "sb_light_switch"
    static let sbLightModeSelect = "sb_light_mode_select"
    static let sbDisableGridExportSwitch = "sb_disable_grid_export_switch"
    static let sbDeviceTimeout = "sb_device_timeout"
    static let sbUsageMode = "sb_usage_mode"
    static let sb3rdPartyPvSwitch = "sb_3rd_party_pv_switch"
    static let sbEvChargerSwitch = "sb_ev_charger_switch"
    static let plugSchedule = "plug_schedule"
    static let plugDelayedToggle = "plug_delayed_toggle"
    static let devicePowerMode = "device_power_mode"
    static let evChargerModeSelect = "ev_charger_mode_select"
    static let evAutoStartSwitch = "ev_auto_start_switch"
    static let evAutoChargeRestartSwitch = "ev_auto_charge_restart_switch"
    static let smartTouchModeSelect = "smart_touch_mode_select"
    static let swipeUpModeSelect = "swipe_up_mode_select"
    static let swipeDownModeSelect = "swipe_down_mode_select"
    static let evChargerScheduleTimes = "ev_charger_schedule_times"
    static let evChargerScheduleSettings = "ev_charger_schedule_settings"
    static let evMaxChargeCurrent = "ev_max_charge_current"
    static let evRandomDelaySwitch = "ev_random_delay_switch"
    static let modbusSwitch = "modbus_switch"
    static let lightBrightness = "light_brightness"
    static let lightOffSchedule = "light_off_schedule"
    static let mainBreakerLimit = "main_breaker_limit"
    static let evLoadBalancing = "ev_load_balancing"
    static let evSolarCharging = "ev_solar_charging"
}

// MARK: - Command Map

@MainActor
struct MqttCommandMap {
    typealias StateConverter = (_ value: Any?, _ state: Any?) -> Any?

    private static func merged(_ left: [String: Any], _ right: [String: Any]) -> [String: Any] {
        left.merging(right) { _, new in new }
    }

    private static let acOutputModeConverter: StateConverter = { value, state in
        if let value = value as? Int {
            return [0: 2, 1: 1][value] ?? 2
        }
        if let state = state as? Int {
            return [2: 0, 1: 1][state] ?? 0
        }
        return nil
    }

    private static let dc12vOutputModeConverter: StateConverter = { value, state in
        if let value = value as? Int {
            return [0: 2, 1: 1][value] ?? 2
        }
        if let state = state as? Int {
            return [2: 0, 1: 1][state] ?? 0
        }
        return nil
    }

    // MARK: - Common field pieces

    static let timestampFD: [String: Any] = [
        "fd": [
            MqttMapKeys.name: "msg_timestamp",
            MqttMapKeys.type: DeviceHexDataType.str.rawValue,
        ]
    ]

    static let timestampFE: [String: Any] = [
        "fe": [
            MqttMapKeys.name: "msg_timestamp",
            MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
        ]
    ]

    static let timestampFENoType: [String: Any] = [
        "fe": [
            MqttMapKeys.name: "msg_timestamp",
            MqttMapKeys.type: DeviceHexDataType.unk.rawValue,
        ]
    ]

    static let timeSile: [String: Any] = [
        MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
        MqttMapKeys.valueMin: 0,
        MqttMapKeys.valueMax: 5947,
        MqttMapKeys.valueStep: 1,
    ]

    static let timeVar: [String: Any] = [
        MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
        MqttMapKeys.length: 3,
        MqttMapKeys.valueMin: 0,
        MqttMapKeys.valueMax: 1_522_491,
        MqttMapKeys.valueStep: 1,
    ]

    static let cmdCommon: [String: Any] = merged(
        [
            MqttMapKeys.topic: "req",
            "a1": [MqttMapKeys.name: "pattern_22"],
        ],
        timestampFE
    )

    static let cmdCommonV2: [String: Any] = merged(
        [
            MqttMapKeys.topic: "req",
            "a1": [MqttMapKeys.name: "pattern_22"],
        ],
        timestampFD
    )

    // MARK: - Commands

    static let cmdStatusRequest: [String: Any] = merged(
        cmdCommon,
        [MqttMapKeys.commandName: SolixMqttCommands.statusRequest]
    )

    static let cmdRealtimeTrigger: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.realtimeTrigger,
            "a2": [
                MqttMapKeys.name: "set_realtime_trigger",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
                MqttMapKeys.valueDefault: 1,
            ],
            "a3": [
                MqttMapKeys.name: "trigger_timeout_sec",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
                MqttMapKeys.valueMin: 60,
                MqttMapKeys.valueMax: 600,
                MqttMapKeys.valueDefault: 60,
            ],
        ]
    )

    static let cmdTimerRequest: [String: Any] = merged(
        cmdCommon,
        [MqttMapKeys.commandName: SolixMqttCommands.timerRequest]
    )

    static let cmdTempUnit: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.tempUnitSwitch,
            "a2": [
                MqttMapKeys.name: "set_temp_unit_fahrenheit",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "temp_unit_fahrenheit",
                MqttMapKeys.valueOptions: ["celsius": 0, "fahrenheit": 1],
            ],
        ]
    )

    static let cmdDeviceMaxLoad: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.deviceMaxLoad,
            "a2": [
                MqttMapKeys.name: "set_device_max_load",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "max_load",
            ],
        ]
    )

    static let cmdDeviceTimeoutMin: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.deviceTimeoutMinutes,
            "a2": [
                MqttMapKeys.name: "set_device_timeout_min",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "device_timeout_minutes",
                MqttMapKeys.valueOptions: [0, 30, 60, 120, 240, 360, 720, 1440],
            ],
        ]
    )

    static let cmdAcChargeSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.acChargeSwitch,
            "a2": [
                MqttMapKeys.name: "set_ac_charge_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "backup_charge_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdAcChargeLimit: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.acChargeLimit,
            "a2": [
                MqttMapKeys.name: "set_ac_input_limit",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "ac_input_limit",
            ],
        ]
    )

    static let cmdAcOutputSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.acOutputSwitch,
            "a2": [
                MqttMapKeys.name: "set_ac_output_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "ac_output_power_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdAcFastChargeSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.acFastChargeSwitch,
            "a2": [
                MqttMapKeys.name: "set_ac_fast_charge_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "fast_charge_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdAcOutputMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.acOutputModeSelect,
            "a2": [
                MqttMapKeys.name: "set_ac_output_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "ac_output_mode",
                MqttMapKeys.stateConverter: acOutputModeConverter,
                MqttMapKeys.valueOptions: ["smart": 0, "normal": 1],
            ],
        ]
    )

    static let cmdAcOutputTimeoutSec: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.acOutputTimeoutSeconds,
            "a2": [
                MqttMapKeys.name: "set_ac_output_timeout_seconds",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
                MqttMapKeys.stateName: "ac_output_timeout_seconds",
                MqttMapKeys.valueMin: 0,
                MqttMapKeys.valueMax: 86400,
                MqttMapKeys.valueStep: 300,
            ],
        ]
    )

    static let cmdDcOutputSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.dcOutputSwitch,
            "a2": [
                MqttMapKeys.name: "set_dc_output_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "dc_output_power_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdDc12vOutputMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.dc12vOutputModeSelect,
            "a2": [
                MqttMapKeys.name: "set_dc_12v_output_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "dc_12v_output_mode",
                MqttMapKeys.stateConverter: dc12vOutputModeConverter,
                MqttMapKeys.valueOptions: ["smart": 0, "normal": 1],
            ],
        ]
    )

    static let cmdDcOutputTimeoutSec: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.dcOutputTimeoutSeconds,
            "a2": [
                MqttMapKeys.name: "set_dc_output_timeout_seconds",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
                MqttMapKeys.stateName: "dc_output_timeout_seconds",
                MqttMapKeys.valueMin: 0,
                MqttMapKeys.valueMax: 86400,
                MqttMapKeys.valueStep: 300,
            ],
        ]
    )

    static let cmdLightSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.lightSwitch,
            "a2": [
                MqttMapKeys.name: "set_light_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "light_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdLightMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.lightModeSelect,
            "a2": [
                MqttMapKeys.name: "set_light_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "light_mode",
                MqttMapKeys.valueOptions: [
                    "off": 0,
                    "low": 1,
                    "medium": 2,
                    "high": 3,
                    "blinking": 4,
                ],
            ],
        ]
    )

    static let cmdDisplaySwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.displaySwitch,
            "a2": [
                MqttMapKeys.name: "set_display_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "display_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdDisplayMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.displayModeSelect,
            "a2": [
                MqttMapKeys.name: "set_display_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "display_mode",
                MqttMapKeys.valueOptions: ["off": 0, "low": 1, "medium": 2, "high": 3],
            ],
        ]
    )

    static let cmdDisplayTimeoutSec: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.displayTimeoutSeconds,
            "a2": [
                MqttMapKeys.name: "set_display_timeout_sec",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "display_timeout_seconds",
                MqttMapKeys.valueOptions: [20, 30, 60, 300, 1800],
            ],
        ]
    )

    static let cmdPortMemorySwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.portMemorySwitch,
            "a2": [
                MqttMapKeys.name: "set_port_memory_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "port_memory_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdUsbPortSwitch: [String: Any] = merged(
        cmdCommon,
        [
            "a2": [
                MqttMapKeys.name: "set_port_switch_select",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["C1": 0, "C2": 1, "C3": 2, "C4": 3, "A": 4],
            ],
            "a3": [
                MqttMapKeys.name: "set_port_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdSocLimitsV2: [String: Any] = merged(
        cmdCommonV2,
        [
            MqttMapKeys.commandName: SolixMqttCommands.socLimits,
            "aa": [
                MqttMapKeys.name: "set_max_soc",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "max_soc",
                MqttMapKeys.valueOptions: [80, 85, 90, 95, 100],
                MqttMapKeys.valueState: "max_soc",
            ],
            "ab": [
                MqttMapKeys.name: "set_min_soc",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "power_cutoff",
                MqttMapKeys.valueOptions: [1, 5, 10, 15, 20],
                MqttMapKeys.valueState: "power_cutoff",
            ],
        ]
    )

    static let cmdSbStatusCheck: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbStatusCheck,
            "a2": [
                MqttMapKeys.name: "device_sn",
                MqttMapKeys.type: DeviceHexDataType.str.rawValue,
                MqttMapKeys.length: 16,
            ],
            "a3": [
                MqttMapKeys.name: "charging_status",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
            ],
            "a4": [
                MqttMapKeys.name: "set_output_preset",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "a5": [
                MqttMapKeys.name: "status_timeout_sec?",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "a6": [
                MqttMapKeys.name: "local_timestamp",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "a7": [
                MqttMapKeys.name: "next_status_timestamp",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "a8": [
                MqttMapKeys.name: "status_check_unknown_1?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
            ],
            "a9": [
                MqttMapKeys.name: "status_check_unknown_2?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
            ],
            "aa": [
                MqttMapKeys.name: "status_check_unknown_3?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
            ],
        ]
    )

    static let cmdSbPowerCutoff: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbPowerCutoffSelect,
            "a2": [
                MqttMapKeys.name: "set_output_cutoff_data",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "output_cutoff_data",
                MqttMapKeys.valueOptions: [5, 10],
            ],
            "a3": [
                MqttMapKeys.name: "set_lowpower_input_data",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "lowpower_input_data",
                MqttMapKeys.valueFollows: "set_output_cutoff_data",
                MqttMapKeys.valueOptions: [5: 4, 10: 5],
            ],
            "a4": [
                MqttMapKeys.name: "set_input_cutoff_data",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "input_cutoff_data",
                MqttMapKeys.valueFollows: "set_output_cutoff_data",
                MqttMapKeys.valueOptions: [5: 5, 10: 10],
            ],
        ]
    )

    static let cmdSbMinSoc: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbMinSocSelect,
            "a2": [
                MqttMapKeys.name: "set_min_soc",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "power_cutoff",
                MqttMapKeys.valueOptions: [5, 10],
            ],
        ]
    )

    static let cmdSbInverterType: [String: Any] = merged(
        cmdSbPowerCutoff,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbInverterTypeSelect,
            "a5": [
                MqttMapKeys.name: "set_inverter_brand",
                MqttMapKeys.type: DeviceHexDataType.bin.rawValue,
            ],
            "a6": [
                MqttMapKeys.name: "set_inverter_model",
                MqttMapKeys.type: DeviceHexDataType.bin.rawValue,
            ],
            "a7": [
                MqttMapKeys.name: "set_min_load",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
            ],
            "a8": [
                MqttMapKeys.name: "set_max_load",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
            ],
            "a9": [
                MqttMapKeys.name: "set_inverter_unknown_1?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
            ],
            "aa": [
                MqttMapKeys.name: "set_ch_1_min_what?",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "ab": [
                MqttMapKeys.name: "set_ch_1_max_what?",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "ac": [
                MqttMapKeys.name: "set_ch_2_min_what?",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
            "ad": [
                MqttMapKeys.name: "set_ch_2_max_what?",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
            ],
        ]
    )

    static let cmdSbAcSocketSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbAcSocketSwitch,
            "a2": [
                MqttMapKeys.name: "set_ac_socket_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "ac_socket_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdSb3rdPartyPvSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sb3rdPartyPvSwitch,
            "a2": [
                MqttMapKeys.name: "set_3rd_party_pv_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "3rd_party_pv_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdSbEvChargerSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbEvChargerSwitch,
            "a2": [
                MqttMapKeys.name: "set_ev_charger_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "ev_charger_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdSbMaxLoad: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbMaxLoad,
            "a2": [
                MqttMapKeys.name: "set_max_load",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "max_load",
            ],
            "a3": [
                MqttMapKeys.name: "set_max_load_type",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.valueDefault: 0,
                MqttMapKeys.valueOptions: ["individual": 0, "parallel": 2, "single": 3],
            ],
        ]
    )

    static let cmdSbDisableGridExportSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbDisableGridExportSwitch,
            "a5": [
                MqttMapKeys.name: "set_disable_grid_export_a5?",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.valueDefault: 0,
            ],
            "a6": [
                MqttMapKeys.name: "set_disable_grid_export_switch",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "grid_export_disabled",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
                MqttMapKeys.valueState: "grid_export_disabled",
            ],
            "a9": [
                MqttMapKeys.name: "set_grid_export_limit",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.valueDefault: 0,
                MqttMapKeys.valueState: "grid_export_limit",
                MqttMapKeys.valueMin: 0,
                MqttMapKeys.valueMax: 100000,
                MqttMapKeys.valueStep: 100,
            ],
        ]
    )

    static let cmdSbPvLimit: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbPvLimitSelect,
            "a7": [
                MqttMapKeys.name: "set_sb_pv_limit_select",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "pv_limit",
                MqttMapKeys.valueOptions: [2000, 3600],
            ],
        ]
    )

    static let cmdSbAcInputLimit: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbAcInputLimit,
            "a8": [
                MqttMapKeys.name: "set_ac_input_limit",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "ac_input_limit",
                MqttMapKeys.valueMin: 0,
                MqttMapKeys.valueMax: 1200,
                MqttMapKeys.valueStep: 100,
            ],
        ]
    )

    static let cmdSbLightSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbLightSwitch,
            "a2": [
                MqttMapKeys.name: "set_light_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueState: "light_mode",
                MqttMapKeys.stateName: "light_mode",
                MqttMapKeys.valueDefault: 0,
            ],
            "a3": [
                MqttMapKeys.name: "set_light_off_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "light_off_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdSbLightMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbLightModeSelect,
            "a2": [
                MqttMapKeys.name: "set_light_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "light_mode",
                MqttMapKeys.valueOptions: ["normal": 0, "mood": 1],
            ],
            "a3": [
                MqttMapKeys.name: "set_light_off_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueState: "light_off_switch",
                MqttMapKeys.stateName: "light_off_switch",
                MqttMapKeys.valueDefault: 0,
            ],
        ]
    )

    static let cmdSbDeviceTimeout: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbDeviceTimeout,
            "a2": [
                MqttMapKeys.name: "set_device_timeout_min",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "device_timeout_minutes",
                MqttMapKeys.valueOptions: [0, 30, 60, 120, 240, 360, 720, 1440],
                MqttMapKeys.valueDivider: 30,
            ],
        ]
    )

    static let useTimeSlot: [String: Any] = [
        MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
        MqttMapKeys.valueOptions: ["discharge": 1, "charge": 4, "default": 6],
        MqttMapKeys.valueDefault: 6,
    ]

    static let cmdSbUsageMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.sbUsageMode,
            "a2": [
                MqttMapKeys.name: "set_usage_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "usage_mode",
                MqttMapKeys.valueOptions: [
                    "manual": 1,
                    "smartmeter": 2,
                    "smartplugs": 3,
                    "backup": 4,
                    "use_time": 5,
                    "smart": 7,
                    "time_slot": 8,
                ],
            ],
            "a3": [
                MqttMapKeys.name: "set_timestamp_a3_or_0?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
            ],
            "a4": [
                MqttMapKeys.name: "set_backup_charge_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "backup_charge_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
                MqttMapKeys.valueDefault: 0,
            ],
            "a5": [
                MqttMapKeys.name: "set_dynamic_soc_limit",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "dynamic_soc_limit",
                MqttMapKeys.valueMin: 10,
                MqttMapKeys.valueMax: 100,
                MqttMapKeys.valueDefault: 0,
            ],
            "a6": [
                MqttMapKeys.name: "set_timestamp_backup_start",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
                MqttMapKeys.stateName: "timestamp_backup_start",
            ],
            "a6_mode_8": [
                MqttMapKeys.name: "set_time_slot_modes",
                MqttMapKeys.type: DeviceHexDataType.bin.rawValue,
                MqttMapKeys.bytes: [
                    "00": useTimeSlot,
                    "01": useTimeSlot,
                    "02": useTimeSlot,
                    "03": useTimeSlot,
                    "04": useTimeSlot,
                    "05": useTimeSlot,
                    "06": useTimeSlot,
                    "07": useTimeSlot,
                    "08": useTimeSlot,
                    "09": useTimeSlot,
                    "10": useTimeSlot,
                    "11": useTimeSlot,
                    "12": useTimeSlot,
                    "13": useTimeSlot,
                    "14": useTimeSlot,
                    "15": useTimeSlot,
                    "16": useTimeSlot,
                    "17": useTimeSlot,
                    "18": useTimeSlot,
                    "19": useTimeSlot,
                    "20": useTimeSlot,
                    "21": useTimeSlot,
                    "22": useTimeSlot,
                    "23": useTimeSlot,
                    "24": useTimeSlot,
                    "25": useTimeSlot,
                    "26": useTimeSlot,
                    "27": useTimeSlot,
                    "28": useTimeSlot,
                    "29": useTimeSlot,
                    "30": useTimeSlot,
                    "31": useTimeSlot,
                    "32": useTimeSlot,
                    "33": useTimeSlot,
                    "34": useTimeSlot,
                    "35": useTimeSlot,
                    "36": useTimeSlot,
                    "37": useTimeSlot,
                    "38": useTimeSlot,
                    "39": useTimeSlot,
                    "40": useTimeSlot,
                    "41": useTimeSlot,
                    "42": useTimeSlot,
                    "43": useTimeSlot,
                    "44": useTimeSlot,
                    "45": useTimeSlot,
                    "46": useTimeSlot,
                    "47": useTimeSlot,
                    "48": useTimeSlot,
                ],
            ],
            "a7": [
                MqttMapKeys.name: "set_timestamp_backup_end",
                MqttMapKeys.type: DeviceHexDataType.`var`.rawValue,
                MqttMapKeys.stateName: "timestamp_backup_end",
            ],
        ]
    )

    static let cmdPlugSchedule: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.plugSchedule,
            "a2": [
                MqttMapKeys.name: "set_plug_schedule_a2?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueDefault: 1,
            ],
            "a3": [
                MqttMapKeys.name: "set_plug_schedule_order?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueMin: 1,
                MqttMapKeys.valueMax: 10,
            ],
            "a4": [
                MqttMapKeys.name: "set_plug_schedule_a4?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueDefault: 1,
            ],
            "a5": merged(
                timeSile,
                [MqttMapKeys.name: "set_plug_schedule_time"]
            ),
            "a6": [
                MqttMapKeys.name: "set_plug_schedule_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdPlugDelayedToggle: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.plugDelayedToggle,
            "a2": [
                MqttMapKeys.name: "set_toggle_to_switch?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a3": [
                MqttMapKeys.type: DeviceHexDataType.bin.rawValue,
                MqttMapKeys.length: 3,
                MqttMapKeys.bytes: [
                    "00": merged(
                        timeVar,
                        [
                            MqttMapKeys.name: "set_toggle_to_delay_time",
                            MqttMapKeys.valueDefault: 0,
                        ]
                    )
                ],
            ],
            "a4": [
                MqttMapKeys.name: "set_toggle_back_switch?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a5": [
                MqttMapKeys.type: DeviceHexDataType.bin.rawValue,
                MqttMapKeys.length: 3,
                MqttMapKeys.bytes: [
                    "00": merged(
                        timeVar,
                        [
                            MqttMapKeys.name: "set_toggle_back_delay_time",
                            MqttMapKeys.valueDefault: 0,
                        ]
                    )
                ],
            ],
        ]
    )

    static let cmdEvChargerMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evChargerModeSelect,
            "a2": [
                MqttMapKeys.name: "set_ev_charger_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["start_charge": 1, "stop_charge": 2, "boost_charge": 4],
            ],
        ]
    )

    static let cmdDevicePowerMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.devicePowerMode,
            "a2": [
                MqttMapKeys.name: "set_device_power_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.valueOptions: ["restart": 5],
                MqttMapKeys.valueDefault: 5,
            ],
        ]
    )

    static let cmdEvAutoStartSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evAutoStartSwitch,
            "a4": [
                MqttMapKeys.name: "set_auto_start_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "auto_start_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdEvMaxChargeCurrent: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evMaxChargeCurrent,
            "a8": [
                MqttMapKeys.name: "set_max_evcharge_current",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "max_evcharge_current",
                MqttMapKeys.valueMin: 6,
                MqttMapKeys.valueMinState: "min_current_limit",
                MqttMapKeys.valueMax: 16,
                MqttMapKeys.valueMaxState: "max_current_limit",
                MqttMapKeys.valueStep: 1,
                MqttMapKeys.valueDivider: 0.1,
            ],
        ]
    )

    static let cmdEvLightBrightness: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.lightBrightness,
            "aa": [
                MqttMapKeys.name: "set_light_brightness",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "light_brightness",
                MqttMapKeys.valueMin: 0,
                MqttMapKeys.valueMax: 100,
                MqttMapKeys.valueStep: 10,
            ],
        ]
    )

    static let cmdEvLightOffSchedule: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.lightOffSchedule,
            "b4": [
                MqttMapKeys.name: "set_light_off_schedule_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "light_off_schedule_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
                MqttMapKeys.valueState: "light_off_schedule_switch",
            ],
            "b5": merged(
                timeSile,
                [
                    MqttMapKeys.name: "set_light_off_start_time",
                    MqttMapKeys.stateName: "light_off_start_time",
                    MqttMapKeys.valueState: "light_off_start_time",
                ]
            ),
            "b6": merged(
                timeSile,
                [
                    MqttMapKeys.name: "set_light_off_end_time",
                    MqttMapKeys.stateName: "light_off_end_time",
                    MqttMapKeys.valueState: "light_off_end_time",
                ]
            ),
        ]
    )

    static let cmdEvAutoChargeRestartSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evAutoChargeRestartSwitch,
            "ac": [
                MqttMapKeys.name: "set_auto_charge_restart_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "auto_charge_restart_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdEvChargeRandomDelaySwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evRandomDelaySwitch,
            "ad": [
                MqttMapKeys.name: "set_random_delay_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "random_delay_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdSwipeUpMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.swipeUpModeSelect,
            "af": [
                MqttMapKeys.name: "set_wipe_up_mode_select",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "wipe_up_mode",
                MqttMapKeys.valueOptions: [
                    "off": 0,
                    "start_charge": 1,
                    "stop_charge": 2,
                    "boost_charge": 3,
                ],
            ],
        ]
    )

    static let cmdSwipeDownMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.swipeDownModeSelect,
            "b0": [
                MqttMapKeys.name: "set_wipe_down_mode_select",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "wipe_down_mode",
                MqttMapKeys.valueOptions: [
                    "off": 0,
                    "start_charge": 1,
                    "stop_charge": 2,
                    "boost_charge": 3,
                ],
            ],
        ]
    )

    static let cmdSmartTouchMode: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.smartTouchModeSelect,
            "b2": [
                MqttMapKeys.name: "set_smart_touch_mode_select",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "smart_touch_mode",
                MqttMapKeys.valueOptions: ["simple": 0, "anti_mistouch": 1],
            ],
        ]
    )

    static let cmdModbusSwitch: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.modbusSwitch,
            "b7": [
                MqttMapKeys.name: "set_modbus_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "modbus_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
        ]
    )

    static let cmdMainBreakerLimit: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.mainBreakerLimit,
            "a3": [
                MqttMapKeys.name: "set_main_breaker_limit",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "main_breaker_limit",
                MqttMapKeys.valueMin: 10,
                MqttMapKeys.valueMax: 500,
                MqttMapKeys.valueStep: 1,
            ],
        ]
    )

    static let cmdEvLoadBalancing: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evLoadBalancing,
            "a2": [
                MqttMapKeys.name: "set_load_balance_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "load_balance_switch",
                MqttMapKeys.valueState: "load_balance_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a4": [
                MqttMapKeys.name: "set_load_balance_setting_d5",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "load_balance_setting_d5",
                MqttMapKeys.valueState: "load_balance_setting_d5",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a5": [
                MqttMapKeys.name: "set_load_balance_setting_d6",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "load_balance_setting_d6",
                MqttMapKeys.valueState: "load_balance_setting_d6",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a6": [
                MqttMapKeys.name: "set_load_balance_monitor_device",
                MqttMapKeys.type: DeviceHexDataType.str.rawValue,
                MqttMapKeys.length: 16,
                MqttMapKeys.stateName: "load_balance_monitor_device",
                MqttMapKeys.valueState: "load_balance_monitor_device",
            ],
        ]
    )

    static let cmdEvSolarCharging: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evLoadBalancing,
            "a2": [
                MqttMapKeys.name: "set_solar_evcharge_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "solar_evcharge_switch",
                MqttMapKeys.valueState: "solar_evcharge_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a3": [
                MqttMapKeys.name: "set_solar_evcharge_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "solar_evcharge_mode",
                MqttMapKeys.valueState: "solar_evcharge_mode",
                MqttMapKeys.valueOptions: ["solar_grid": 0, "solar_only": 1],
            ],
            "a4": [
                MqttMapKeys.name: "set_solar_evcharge_min_current",
                MqttMapKeys.type: DeviceHexDataType.sile.rawValue,
                MqttMapKeys.stateName: "solar_evcharge_min_current",
                MqttMapKeys.valueState: "solar_evcharge_min_current",
                MqttMapKeys.valueMin: 6,
                MqttMapKeys.valueMinState: "min_current_limit",
                MqttMapKeys.valueMax: 16,
                MqttMapKeys.valueMaxState: "max_current_limit",
                MqttMapKeys.valueStep: 1,
            ],
            "a5": [
                MqttMapKeys.name: "set_phase_operating_mode?",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "phase_operating_mode",
                MqttMapKeys.valueState: "phase_operating_mode",
                MqttMapKeys.valueOptions: ["one_phase": 1, "three_phase": 3],
            ],
            "a6": [
                MqttMapKeys.name: "set_auto_phase_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "auto_phase_switch",
                MqttMapKeys.valueState: "auto_phase_switch",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a7": [
                MqttMapKeys.name: "set_solar_evcharge_monitoring_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "solar_evcharge_monitoring_mode",
                MqttMapKeys.valueState: "solar_evcharge_monitoring_mode",
                MqttMapKeys.valueOptions: ["off": 0, "on": 1],
            ],
            "a8": [
                MqttMapKeys.name: "set_solar_evcharge_monitor_device",
                MqttMapKeys.type: DeviceHexDataType.str.rawValue,
                MqttMapKeys.length: 16,
                MqttMapKeys.stateName: "solar_evcharge_monitor_device",
                MqttMapKeys.valueState: "solar_evcharge_monitor_device",
            ],
        ]
    )

    static let cmdEvChargerScheduleSettings: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evChargerScheduleSettings,
            "a2": [
                MqttMapKeys.name: "set_schedule_switch",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "schedule_switch",
                MqttMapKeys.valueState: "schedule_switch",
                MqttMapKeys.valueOptions: ["off": 2, "on": 1],
            ],
            "a8": [
                MqttMapKeys.name: "schedule_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "schedule_mode",
                MqttMapKeys.valueState: "schedule_mode",
                MqttMapKeys.valueOptions: ["normal": 0, "smart": 1],
            ],
        ]
    )

    static let cmdEvChargerScheduleTimes: [String: Any] = merged(
        cmdCommon,
        [
            MqttMapKeys.commandName: SolixMqttCommands.evChargerScheduleTimes,
            "a3": merged(
                timeSile,
                [
                    MqttMapKeys.name: "set_week_start_time",
                    MqttMapKeys.stateName: "week_start_time",
                    MqttMapKeys.valueState: "week_start_time",
                ]
            ),
            "a4": merged(
                timeSile,
                [
                    MqttMapKeys.name: "set_week_end_time",
                    MqttMapKeys.stateName: "week_end_time",
                    MqttMapKeys.valueState: "week_end_time",
                ]
            ),
            "a5": merged(
                timeSile,
                [
                    MqttMapKeys.name: "set_weekend_start_time",
                    MqttMapKeys.stateName: "weekend_start_time",
                    MqttMapKeys.valueState: "weekend_start_time",
                ]
            ),
            "a6": merged(
                timeSile,
                [
                    MqttMapKeys.name: "set_weekend_end_time",
                    MqttMapKeys.stateName: "weekend_end_time",
                    MqttMapKeys.valueState: "weekend_end_time",
                ]
            ),
            "a7": [
                MqttMapKeys.name: "set_weekend_mode",
                MqttMapKeys.type: DeviceHexDataType.ui.rawValue,
                MqttMapKeys.stateName: "weekend_mode",
                MqttMapKeys.valueState: "weekend_mode",
                MqttMapKeys.valueOptions: ["same": 1, "different": 2],
            ],
        ]
    )
}

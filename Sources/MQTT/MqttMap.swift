//
//  MqttMap.swift
//  PowerBankMenu
//
//  Initial MQTT map structure with sample device mappings.
//  This is a minimal subset to validate parsing and lookup.
//

import Foundation

struct MqttMapKeys {
    static let name = "name"
    static let type = "type"
    static let topic = "topic"
    static let factor = "factor"
    static let signed = "signed"
    static let bytes = "bytes"
    static let length = "length"
    static let mask = "mask"
    static let values = "values"
    static let json = "json"
    static let commandName = "command_name"
    static let commandList = "command_list"
    static let stateName = "state_name"
    static let stateConverter = "state_converter"
    static let valueOptions = "value_options"
    static let valueDefault = "value_default"
    static let valueMin = "value_min"
    static let valueMax = "value_max"
    static let valueStep = "value_step"
    static let valueState = "value_state"
    static let valueFollows = "value_follows"
    static let valueDivider = "value_divider"
    static let valueMinState = "value_min_state"
    static let valueMaxState = "value_max_state"
}

private final class MqttMapBundleToken {}

struct MqttMap {
    // Example command maps (subset)
    nonisolated(unsafe) private static let ppsVersions0830: [String: Any] = [
        MqttMapKeys.topic: "param_info",
        "a1": [
            MqttMapKeys.name: "hw_version",
            MqttMapKeys.type: DeviceHexDataType.str.rawValue,
        ],
        "a2": [
            MqttMapKeys.name: "sw_version",
            MqttMapKeys.type: DeviceHexDataType.str.rawValue,
        ],
    ]

    nonisolated(unsafe) private static let a1722_0405: [String: Any] = [
        MqttMapKeys.topic: "param_info",
        "a4": [
            MqttMapKeys.name: "remaining_time_hours",
            MqttMapKeys.factor: 0.1,
            MqttMapKeys.signed: false,
        ],
        "a7": [MqttMapKeys.name: "usbc_1_power"],
        "a8": [MqttMapKeys.name: "usbc_2_power"],
        "a9": [MqttMapKeys.name: "usbc_3_power"],
        "aa": [MqttMapKeys.name: "usba_1_power"],
        "ac": [MqttMapKeys.name: "dc_input_power_total"],
        "ad": [MqttMapKeys.name: "ac_input_power_total"],
        "ae": [MqttMapKeys.name: "ac_output_power_total"],
        "b7": [MqttMapKeys.name: "ac_output_power_switch"],
        "b8": [MqttMapKeys.name: "dc_charging_status"],
        "b9": [MqttMapKeys.name: "temperature", MqttMapKeys.signed: true],
        "ba": [MqttMapKeys.name: "charging_status"],
        "bb": [MqttMapKeys.name: "battery_soc"],
        "bc": [MqttMapKeys.name: "battery_soh"],
        "c1": [MqttMapKeys.name: "dc_output_power_switch"],
        "c5": [MqttMapKeys.name: "device_sn"],
        "cf": [MqttMapKeys.name: "display_mode"],
        "fe": [MqttMapKeys.name: "msg_timestamp"],
    ]

    nonisolated(unsafe) private static let a1728_0405: [String: Any] = [
        MqttMapKeys.topic: "param_info",
        "a3": [
            MqttMapKeys.name: "remaining_time_hours",
            MqttMapKeys.factor: 0.1,
            MqttMapKeys.signed: false,
        ],
        "a4": [MqttMapKeys.name: "usbc_1_power"],
        "a5": [MqttMapKeys.name: "usbc_2_power"],
        "a6": [MqttMapKeys.name: "usbc_3_power"],
        "a7": [MqttMapKeys.name: "usbc_4_power"],
        "a8": [MqttMapKeys.name: "usba_1_power"],
        "a9": [MqttMapKeys.name: "usba_2_power"],
        "aa": [MqttMapKeys.name: "dc_input_power"],
        "ab": [MqttMapKeys.name: "photovoltaic_power"],
        "ac": [MqttMapKeys.name: "dc_input_power_total"],
        "ad": [MqttMapKeys.name: "output_power_total"],
        "b5": [MqttMapKeys.name: "temperature", MqttMapKeys.signed: true],
        "b6": [MqttMapKeys.name: "charging_status"],
        "b7": [MqttMapKeys.name: "battery_soc"],
        "b8": [MqttMapKeys.name: "battery_soh"],
        "b9": [MqttMapKeys.name: "usbc_1_status"],
        "ba": [MqttMapKeys.name: "usbc_2_status"],
        "bb": [MqttMapKeys.name: "usbc_3_status"],
        "bc": [MqttMapKeys.name: "usbc_4_status"],
        "bd": [MqttMapKeys.name: "usba_1_status"],
        "be": [MqttMapKeys.name: "usba_2_status"],
        "bf": [MqttMapKeys.name: "light_switch"],
        "c4": [MqttMapKeys.name: "dc_output_timeout_seconds"],
        "c5": [MqttMapKeys.name: "display_timeout_seconds"],
        "c8": [MqttMapKeys.name: "display_mode"],
        "fe": [MqttMapKeys.name: "msg_timestamp"],
    ]

    // Map format: model -> msgTypeHex -> fieldMap
    nonisolated(unsafe) private static let sampleMap: [String: [String: [String: Any]]] = [
        "A1722": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1728": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        // PPS fallback coverage (use A1722/A1728 mappings when mqttmap.json is missing)
        "A1723": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1725": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1726": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1727": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1729": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1753": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1754": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1755": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1761": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1762": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1763": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1765": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1770": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1771": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1772": [
            "0405": a1722_0405,
            "0830": ppsVersions0830,
        ],
        "A1780": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        "A1780P": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        "A1781": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        "A1782": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        "A1783": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        "A1790": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
        "A1790P": [
            "0405": a1728_0405,
            "0830": ppsVersions0830,
        ],
    ]

    nonisolated(unsafe) static let map: [String: [String: [String: Any]]] = loadMap()

    private static let jsonFileName = "mqttmap.json"

    private static func loadMap() -> [String: [String: [String: Any]]] {
        if let jsonMap = loadJsonMap() {
            return mergeFallbacks(base: jsonMap)
        }
        print("MqttMap: using sample map (mqttmap.json not found or invalid)")
        return sampleMap
    }

    private static func loadJsonMap() -> [String: [String: [String: Any]]]? {
        for url in candidateUrls() {
            guard let data = try? Data(contentsOf: url) else { continue }
            guard let obj = try? JSONSerialization.jsonObject(with: data),
                let dict = obj as? [String: Any]
            else { continue }
            if let map = castMqttMap(dict) {
                print("MqttMap: loaded mqttmap.json from \(url.path)")
                return map
            }
        }
        return nil
    }

    private static func candidateUrls() -> [URL] {
        var urls: [URL] = []
        #if SWIFT_PACKAGE
            if let url = Bundle.module.url(forResource: "mqttmap", withExtension: "json") {
                urls.append(url)
            }
        #endif
        let frameworkBundle = Bundle(for: MqttMapBundleToken.self)
        if let url = frameworkBundle.url(forResource: "mqttmap", withExtension: "json") {
            urls.append(url)
        }
        if let url = Bundle.main.url(forResource: "mqttmap", withExtension: "json") {
            urls.append(url)
        }
        let sourceRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        urls.append(sourceRoot.appendingPathComponent(jsonFileName))
        urls.append(
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(jsonFileName)
        )
        return urls
    }

    private static func castMqttMap(_ dict: [String: Any]) -> [String: [String: [String: Any]]]? {
        var result: [String: [String: [String: Any]]] = [:]
        for (model, value) in dict {
            guard let msgTypes = value as? [String: Any] else { continue }
            var msgMap: [String: [String: Any]] = [:]
            for (msgType, msgValue) in msgTypes {
                guard let fields = msgValue as? [String: Any] else { continue }
                msgMap[msgType] = fields
            }
            if !msgMap.isEmpty {
                result[model] = msgMap
            }
        }
        return result.isEmpty ? nil : result
    }

    private static func mergeFallbacks(
        base: [String: [String: [String: Any]]]
    ) -> [String: [String: [String: Any]]] {
        var merged = base
        for (model, map) in sampleMap {
            if merged[model] == nil {
                merged[model] = map
            }
        }
        return merged
    }
}

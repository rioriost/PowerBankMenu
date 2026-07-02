//
//  MqttDeviceFactory.swift
//  PowerBankMenu
//
//  Simplified MQTT device factory using Solix device classes.
//  Swift port of anker-solix-api/api/mqtt_factory.py
//

import Foundation

struct SolixMqttDeviceFactory {
    let api: SolixApi
    let deviceSn: String

    func createDevice() -> SolixMqttDevice? {
        if let direct = api.devices[deviceSn] {
            return createDevice(device: direct)
        }
        if let match = api.devices.values.first(where: { ($0["device_sn"] as? String) == deviceSn }) {
            return createDevice(device: match)
        }
        return nil
    }

    func createDevice(device: [String: Any]) -> SolixMqttDevice? {
        let pn = (device["device_pn"] as? String) ?? (device["product_code"] as? String) ?? ""
        guard !pn.isEmpty else { return nil }

        let deviceType = device["type"] as? String
        let inferredType: String? = {
            if SolixMqttDevicePps.models.contains(pn) { return SolixDeviceType.pps.rawValue }
            if SolixMqttDeviceSolarbank.models.contains(pn) {
                return SolixDeviceType.solarbank.rawValue
            }
            if SolixMqttDeviceCharger.models.contains(pn) { return SolixDeviceType.charger.rawValue }
            if SolixMqttDeviceVarious.models.contains(pn) { return SolixDeviceType.smartplug.rawValue }
            return nil
        }()
        let resolvedType = deviceType ?? inferredType

        // If map is missing, still allow realtime trigger only.
        if MqttMap.map[pn] != nil, let resolvedType {
            if resolvedType == SolixDeviceType.pps.rawValue {
                return SolixMqttDevicePps(api: api, deviceSn: deviceSn)
            }

            if [SolixDeviceType.solarbank.rawValue, SolixDeviceType.combinerBox.rawValue]
                .contains(resolvedType)
            {
                return SolixMqttDeviceSolarbank(api: api, deviceSn: deviceSn)
            }

            if [SolixDeviceType.charger.rawValue, SolixDeviceType.evCharger.rawValue]
                .contains(resolvedType)
            {
                return SolixMqttDeviceCharger(api: api, deviceSn: deviceSn)
            }

            if resolvedType == SolixDeviceType.smartplug.rawValue {
                return SolixMqttDeviceVarious(api: api, deviceSn: deviceSn)
            }
        }

        // Default device supporting only realtime trigger control
        return SolixMqttDevice(
            api: api,
            deviceSn: deviceSn,
            models: [],
            features: [
                SolixMqttCommands.realtimeTrigger: []
            ]
        )
    }
}

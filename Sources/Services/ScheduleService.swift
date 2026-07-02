//
//  ScheduleService.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/schedule.py (core schedule endpoints)
//

import Foundation

final class ScheduleService {
    private let api: SolixApi

    init(api: SolixApi) {
        self.api = api
    }

    // MARK: - Helpers

    private func decodeJsonString(_ value: Any?) -> [String: Any]? {
        guard let string = value as? String,
            let data = string.data(using: .utf8)
        else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    }

    private func encodeJsonString(_ value: Any) -> String? {
        guard JSONSerialization.isValidJSONObject(value),
            let data = try? JSONSerialization.data(withJSONObject: value, options: []),
            let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    // MARK: - Device Load (SB1)

    func getDeviceLoad(
        siteId: String,
        deviceSn: String,
        testSchedule: [String: Any]? = nil
    ) async throws -> [String: Any] {
        var schedule: [String: Any] = [:]
        var data: [String: Any] = [:]

        if let testSchedule {
            schedule = testSchedule
        } else {
            let payload: [String: Any] = [
                "site_id": siteId,
                "device_sn": deviceSn,
            ]
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["get_device_load"] ?? "",
                json: payload
            )
            data = (response["data"] as? [String: Any]) ?? [:]

            if let decoded = decodeJsonString(data["home_load_data"]) {
                data["home_load_data"] = decoded
            }
            schedule = (data["home_load_data"] as? [String: Any]) ?? [:]
        }

        // Update schedule for all SB1 devices at site
        for (sn, device) in api.devices
        where (device["site_id"] as? String) == siteId
            && (device["type"] as? String) == SolixDeviceType.solarbank.rawValue
            && (device["generation"] as? Int ?? 0) <= 1
        {
            _ = api._update_dev(
                devData: [
                    "device_sn": sn,
                    "schedule": schedule,
                    "current_home_load": data["current_home_load"] ?? "",
                    "parallel_home_load": data["parallel_home_load"] ?? "",
                ]
            )
        }

        return data
    }

    func setDeviceLoad(
        siteId: String,
        deviceSn: String,
        loadData: [String: Any]
    ) async throws -> [String: Any] {
        guard let jsonString = encodeJsonString(loadData) else {
            throw AnkerSolixError.request(message: "Invalid home_load_data JSON")
        }

        let payload: [String: Any] = [
            "site_id": siteId,
            "device_sn": deviceSn,
            "home_load_data": jsonString,
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["set_device_load"] ?? "",
            json: payload
        )

        try ApiErrorMapper.throwIfError(from: response)
        return try await getDeviceLoad(siteId: siteId, deviceSn: deviceSn)
    }

    // MARK: - Device Parm (Schedule)

    func getDeviceParm(
        siteId: String,
        paramType: String = SolixParmType.solarbankSchedule.rawValue,
        deviceSn: String? = nil,
        testSchedule: [String: Any]? = nil
    ) async throws -> [String: Any] {
        var paramData: [String: Any] = [:]
        var data: [String: Any] = [:]

        if let testSchedule {
            paramData = testSchedule
        } else {
            let payload: [String: Any] = [
                "site_id": siteId,
                "param_type": paramType,
            ]
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["get_device_parm"] ?? "",
                json: payload
            )
            data = (response["data"] as? [String: Any]) ?? [:]

            if let decoded = decodeJsonString(data["param_data"]) {
                data["param_data"] = decoded
            }
            paramData = (data["param_data"] as? [String: Any]) ?? [:]
        }

        // Update schedule for related devices
        let isSb1 = paramType == SolixParmType.solarbankSchedule.rawValue
        let isSb2 = paramType == SolixParmType.solarbank2Schedule.rawValue
        let isStation = paramType == SolixParmType.solarbankStation.rawValue

        if isSb1 || isSb2 {
            var deviceSerials: [String] = []

            for (sn, device) in api.devices
            where (device["site_id"] as? String) == siteId
                && (device["type"] as? String) == SolixDeviceType.solarbank.rawValue
            {
                let generation = device["generation"] as? Int ?? 0
                if isSb1 {
                    if generation <= 1 { deviceSerials.append(sn) }
                } else {
                    if generation >= 2 { deviceSerials.append(sn) }
                }
            }

            var stationSns: Set<String> = []
            for sn in deviceSerials {
                if let stationSn = api.devices[sn]?["station_sn"] as? String {
                    stationSns.insert(stationSn)
                }
                _ = api._update_dev(devData: [
                    "device_sn": sn,
                    "schedule": paramData,
                ])
            }

            for stationSn in stationSns {
                _ = api._update_dev(devData: [
                    "device_sn": stationSn,
                    "schedule": paramData,
                ])
            }
        } else if isStation {
            if !paramData.isEmpty {
                let stationSn =
                    ((api.sites[siteId]?["site_details"] as? [String: Any])?["station_sn"]
                        as? String)
                    ?? ""

                api._update_site(
                    siteId: siteId,
                    details: [
                        "station_settings": paramData,
                        "station_sn": stationSn,
                    ]
                )

                let switch0w =
                    (paramData["switch_0w"] as? Bool)
                    ?? ((paramData["switch_0w"] as? Int) ?? 0 != 0)

                for (sn, device) in api.devices
                where (device["site_id"] as? String) == siteId
                    && (device["type"] as? String) == SolixDeviceType.solarbank.rawValue
                {
                    if sn == stationSn { continue }

                    _ = api._update_dev(devData: [
                        "device_sn": sn,
                        "station_sn": stationSn,
                        "allow_grid_export": !switch0w,
                        "grid_export_limit": "\(paramData["feed-in_power_limit"] ?? "")",
                    ])
                }

                if api.devices[stationSn] != nil {
                    var station: [String: Any] = ["device_sn": stationSn]
                    station["power_cutoff_data"] = paramData["soc_list"] ?? []
                    station["allow_grid_export"] = !switch0w
                    station["grid_export_limit"] = "\(paramData["feed-in_power_limit"] ?? "")"
                    _ = api._update_dev(devData: station)
                }
            }
        }

        if let deviceSn, !deviceSn.isEmpty {
            _ = api._update_dev(devData: [
                "device_sn": deviceSn,
                "schedule": paramData,
            ])
        }

        return data
    }

    func setDeviceParm(
        siteId: String,
        paramData: [String: Any],
        paramType: String = SolixParmType.solarbankSchedule.rawValue,
        command: Int = 17,
        deviceSn: String? = nil
    ) async throws -> [String: Any] {
        guard let jsonString = encodeJsonString(paramData) else {
            throw AnkerSolixError.request(message: "Invalid param_data JSON")
        }

        let payload: [String: Any] = [
            "site_id": siteId,
            "param_type": paramType,
            "cmd": command,
            "param_data": jsonString,
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["set_device_parm"] ?? "",
            json: payload
        )

        try ApiErrorMapper.throwIfError(from: response)

        if paramType == SolixParmType.solarbankSchedule.rawValue {
            return try await getDeviceLoad(siteId: siteId, deviceSn: deviceSn ?? "")
        }

        return try await getDeviceParm(siteId: siteId, paramType: paramType, deviceSn: deviceSn)
    }
}

//
//  EnergyService.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/energy.py (core energy endpoints)
//

import Foundation

final class EnergyService {
    private let api: SolixApi

    init(api: SolixApi) {
        self.api = api
    }

    // MARK: - Helpers

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func addDays(_ date: Date, _ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    private func clampDays(startDay: Date, numDays: Int) -> (Date, Int) {
        let calendar = Calendar.current
        let future = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()

        var start = startDay
        var days = max(1, numDays)

        if start > future {
            start = future
            days = 1
        } else if let end = calendar.date(byAdding: .day, value: days, to: start), end > future {
            let diff = calendar.dateComponents([.day], from: start, to: future).day ?? 0
            days = max(1, diff + 1)
        }

        days = min(366, max(1, days))
        return (start, days)
    }

    private func updateTable(
        _ table: inout [String: [String: Any]],
        day: String,
        updates: [String: Any?]
    ) {
        var entry = table[day] ?? ["date": day]
        for (key, value) in updates {
            entry[key] = value ?? NSNull()
        }
        table[day] = entry
    }

    private func deviceHasSolarChannel(_ device: [String: Any], channel: String) -> Bool {
        if channel.hasPrefix("pv"),
            let index = channel.dropFirst().first,
            let num = Int(String(index))
        {
            if device["solar_power_\(num)"] != nil { return true }
        }
        return device["\(channel)_power"] != nil
    }

    // MARK: - Energy Analysis

    func energyAnalysis(
        siteId: String,
        deviceSn: String,
        rangeType: String? = nil,
        startDay: Date? = nil,
        endDay: Date? = nil,
        devType: String? = nil
    ) async throws -> [String: Any] {
        let range = ["week", "month", "year"].contains(rangeType ?? "") ? rangeType! : "day"
        let start = startDay ?? Date()
        let end = endDay

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch range {
        case "month":
            formatter.dateFormat = "yyyy-MM"
        case "year":
            formatter.dateFormat = "yyyy"
        default:
            formatter.dateFormat = "yyyy-MM-dd"
        }

        let resolvedType: String
        if let devType,
            devType == "solar_production"
                || devType == "solarbank"
                || devType == "home_usage"
                || devType == "grid"
                || devType.hasPrefix("solar_production_")
        {
            resolvedType = devType
        } else {
            resolvedType = "solar_production"
        }

        let payload: [String: Any] = [
            "site_id": siteId,
            "device_sn": deviceSn,
            "device_type": resolvedType,
            "type": range,
            "start_time": formatter.string(from: start),
            "end_time": end == nil ? "" : formatter.string(from: end!),
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["energy_analysis"] ?? "",
            json: payload
        )

        return (response["data"] as? [String: Any]) ?? [:]
    }

    // MARK: - Home Load Chart

    func homeLoadChart(siteId: String, deviceSn: String? = nil) async throws -> [String: Any] {
        var payload: [String: Any] = ["site_id": siteId]
        if let deviceSn {
            payload["device_sn"] = deviceSn
        }

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["home_load_chart"] ?? "",
            json: payload
        )

        return (response["data"] as? [String: Any]) ?? [:]
    }

    // MARK: - Device PV Statistics

    func getDevicePvStatistics(
        deviceSn: String,
        rangeType: String? = nil,
        startDay: Date? = nil,
        endDay: Date? = nil,
        version: String = "1"
    ) async throws -> [String: Any] {
        let range = ["week", "month", "year"].contains(rangeType ?? "") ? rangeType! : "day"
        let start = startDay ?? Date()
        let end = endDay ?? start

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        switch range {
        case "month":
            formatter.dateFormat = "yyyy-MM"
        case "year":
            formatter.dateFormat = "yyyy"
        default:
            formatter.dateFormat = "yyyy-MM-dd"
        }

        let payload: [String: Any] = [
            "sn": deviceSn,
            "type": range,
            "start": formatter.string(from: start),
            "end": formatter.string(from: end),
            "version": version,
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_device_pv_statistics"] ?? "",
            json: payload
        )

        return (response["data"] as? [String: Any]) ?? [:]
    }

    // MARK: - Energy Daily Aggregation

    func energyDaily(
        siteId: String,
        deviceSn: String,
        startDay: Date = Date(),
        numDays: Int = 1,
        dayTotals: Bool = false,
        devTypes: Set<String>? = nil,
        showProgress: Bool = false
    ) async throws -> [String: [String: Any]] {
        var table: [String: [String: Any]] = [:]
        let (start, rangeDays) = clampDays(startDay: startDay, numDays: numDays)
        let device = api.devices[deviceSn] ?? [:]
        let generation = device["generation"] as? Int ?? 0
        let types = devTypes ?? []

        let otherPv =
            ((api.sites[siteId]?["feature_switch"] as? [String: Any])?["show_third_party_pv_panel"]
                as? Bool)
            ?? false

        // Solarbank energy
        if types.contains(SolixDeviceType.solarbank.rawValue) {
            let justifyDayTotals = dayTotals && generation >= 2
            let end = justifyDayTotals ? start : addDays(start, rangeDays - 1)
            let resp = try await energyAnalysis(
                siteId: siteId,
                deviceSn: deviceSn,
                rangeType: "week",
                startDay: start,
                endDay: end,
                devType: "solarbank"
            )

            let items = resp["power"] as? [[String: Any]] ?? []
            for idx in 0..<min(items.count, rangeDays) {
                let item = items[idx]
                let day = (item["time"] as? String) ?? dayString(addDays(start, idx))
                updateTable(
                    &table, day: day,
                    updates: [
                        "battery_discharge": item["value"]
                    ])
            }

            if justifyDayTotals {
                for idx in 0..<rangeDays {
                    let dayDate = addDays(start, idx)
                    let day = dayString(dayDate)
                    let dailyResp: [String: Any]
                    if idx == 0 {
                        dailyResp = resp
                    } else {
                        dailyResp = try await energyAnalysis(
                            siteId: siteId,
                            deviceSn: deviceSn,
                            rangeType: "week",
                            startDay: dayDate,
                            endDay: dayDate,
                            devType: "solarbank"
                        )
                    }

                    updateTable(
                        &table, day: day,
                        updates: [
                            "ac_socket": dailyResp["ac_out_put_total"],
                            "battery_to_home": dailyResp["battery_to_home_total"],
                            "grid_to_battery": dailyResp["grid_to_battery_total"],
                            "3rd_party_pv_to_bat": otherPv
                                ? dailyResp["third_party_pv_to_bat"] : nil,
                        ])

                    if showProgress {
                        api.logger("Received solarbank energy for \(day)")
                    }
                }
            }
        }

        // Home usage
        if (types.contains(SolixDeviceType.solarbank.rawValue) && generation >= 2)
            || types.contains(SolixDeviceType.smartmeter.rawValue)
            || types.contains(SolixDeviceType.smartplug.rawValue)
        {
            let justifyDayTotals = dayTotals
            let end = justifyDayTotals ? start : addDays(start, rangeDays - 1)
            let resp = try await energyAnalysis(
                siteId: siteId,
                deviceSn: deviceSn,
                rangeType: "week",
                startDay: start,
                endDay: end,
                devType: "home_usage"
            )

            let items = resp["power"] as? [[String: Any]] ?? []
            for idx in 0..<min(items.count, rangeDays) {
                let item = items[idx]
                let day = (item["time"] as? String) ?? dayString(addDays(start, idx))
                updateTable(
                    &table, day: day,
                    updates: [
                        "home_usage": item["value"]
                    ])
            }

            if justifyDayTotals {
                for idx in 0..<rangeDays {
                    let dayDate = addDays(start, idx)
                    let day = dayString(dayDate)
                    let dailyResp: [String: Any]
                    if idx == 0 {
                        dailyResp = resp
                    } else {
                        dailyResp = try await energyAnalysis(
                            siteId: siteId,
                            deviceSn: deviceSn,
                            rangeType: "week",
                            startDay: dayDate,
                            endDay: dayDate,
                            devType: "home_usage"
                        )
                    }

                    let smartPlugInfo = dailyResp["smart_plug_info"] as? [String: Any]
                    let smartPlugList = smartPlugInfo?["smartplug_list"] as? [[String: Any]] ?? []
                    let plugList: [[String: Any]] = smartPlugList.map {
                        [
                            "device_sn": $0["device_sn"] as Any,
                            "alias": $0["device_name"] as Any,
                            "energy": $0["total_power"] as Any,
                        ]
                    }

                    updateTable(
                        &table, day: day,
                        updates: [
                            "grid_to_home": dailyResp["grid_to_home_total"],
                            "smartplugs_total": smartPlugInfo?["total_power"],
                            "smartplug_list": plugList.isEmpty ? nil : plugList,
                        ])

                    if showProgress {
                        api.logger("Received home_usage energy for \(day)")
                    }
                }
            }
        }

        // Grid stats
        if types.contains(SolixDeviceType.smartmeter.rawValue)
            && (!types.contains(SolixDeviceType.solarbank.rawValue) || otherPv)
        {
            let resp = try await energyAnalysis(
                siteId: siteId,
                deviceSn: deviceSn,
                rangeType: "week",
                startDay: start,
                endDay: addDays(start, rangeDays - 1),
                devType: "grid"
            )

            let items = resp["power"] as? [[String: Any]] ?? []
            for idx in 0..<min(items.count, rangeDays) {
                let item = items[idx]
                let day = (item["time"] as? String) ?? dayString(addDays(start, idx))
                let solarToGrid = (item["value"] as? String)?.replacingOccurrences(
                    of: "-", with: "")
                updateTable(
                    &table, day: day,
                    updates: [
                        "solar_to_grid": solarToGrid
                    ])
            }

            let chargeItems = resp["charge_trend"] as? [[String: Any]] ?? []
            for idx in 0..<min(chargeItems.count, rangeDays) {
                let item = chargeItems[idx]
                let day = (item["time"] as? String) ?? dayString(addDays(start, idx))
                updateTable(
                    &table, day: day,
                    updates: [
                        "grid_to_home": item["value"]
                    ])
            }

            if dayTotals {
                for idx in 0..<rangeDays {
                    let dayDate = addDays(start, idx)
                    let day = dayString(dayDate)
                    let dailyResp: [String: Any]
                    if idx == 0 {
                        dailyResp = resp
                    } else {
                        dailyResp = try await energyAnalysis(
                            siteId: siteId,
                            deviceSn: deviceSn,
                            rangeType: "week",
                            startDay: dayDate,
                            endDay: dayDate,
                            devType: "grid"
                        )
                    }

                    updateTable(
                        &table, day: day,
                        updates: [
                            "3rd_party_pv_to_grid": otherPv
                                ? dailyResp["third_party_pv_to_grid"] : nil
                        ])

                    if showProgress {
                        api.logger("Received grid energy for \(day)")
                    }
                }
            }
        }

        // Per-channel solar production
        if types.contains(SolixDeviceType.inverter.rawValue) {
            let channels = ["pv1", "pv2", "pv3", "pv4", "micro_inverter"]
            for ch in channels where deviceHasSolarChannel(device, channel: ch) {
                let resp = try await energyAnalysis(
                    siteId: siteId,
                    deviceSn: deviceSn,
                    rangeType: "week",
                    startDay: start,
                    endDay: addDays(start, rangeDays - 1),
                    devType: "solar_production_\(ch.replacingOccurrences(of: "_", with: ""))"
                )
                let items = resp["power"] as? [[String: Any]] ?? []
                for idx in 0..<min(items.count, rangeDays) {
                    let item = items[idx]
                    let day = (item["time"] as? String) ?? dayString(addDays(start, idx))
                    updateTable(
                        &table, day: day,
                        updates: [
                            "solar_production_\(ch.replacingOccurrences(of: "_", with: ""))": item[
                                "value"]
                        ])
                }
                if showProgress {
                    api.logger("Received solar_production_\(ch) energy for period")
                }
            }
        }

        // Always include overall solar production
        let solarResp = try await energyAnalysis(
            siteId: siteId,
            deviceSn: deviceSn,
            rangeType: "week",
            startDay: start,
            endDay: dayTotals ? start : addDays(start, rangeDays - 1),
            devType: "solar_production"
        )
        let solarItems = solarResp["power"] as? [[String: Any]] ?? []
        for idx in 0..<min(solarItems.count, rangeDays) {
            let item = solarItems[idx]
            let day = (item["time"] as? String) ?? dayString(addDays(start, idx))
            updateTable(
                &table, day: day,
                updates: [
                    "solar_production": item["value"]
                ])
        }

        if dayTotals {
            for idx in 0..<rangeDays {
                let dayDate = addDays(start, idx)
                let day = dayString(dayDate)
                let dailyResp: [String: Any]
                if idx == 0 {
                    dailyResp = solarResp
                } else {
                    dailyResp = try await energyAnalysis(
                        siteId: siteId,
                        deviceSn: deviceSn,
                        rangeType: "week",
                        startDay: dayDate,
                        endDay: dayDate,
                        devType: "solar_production"
                    )
                }

                updateTable(
                    &table, day: day,
                    updates: [
                        "battery_charge": dailyResp["charge_total"],
                        "solar_to_grid": dailyResp["solar_to_grid_total"],
                        "solar_to_battery": dailyResp["solar_to_battery_total"],
                        "solar_to_home": dailyResp["solar_to_home_total"],
                        "battery_percentage": dailyResp["charging_pre"],
                        "solar_percentage": dailyResp["electricity_pre"],
                        "other_percentage": dailyResp["others_pre"],
                    ])

                if showProgress {
                    api.logger("Received solar_production energy for \(day)")
                }
            }
        }

        return table
    }

    // MARK: - Device PV Energy Daily (simplified)

    func devicePvEnergyDaily(
        deviceSn: String,
        startDay: Date = Date(),
        numDays: Int = 1
    ) async throws -> [String: [String: Any]] {
        let rangeDays = max(1, min(366, numDays))

        let endDay =
            Calendar.current.date(byAdding: .day, value: rangeDays - 1, to: startDay) ?? startDay
        let stats = try await getDevicePvStatistics(
            deviceSn: deviceSn,
            rangeType: "week",
            startDay: startDay,
            endDay: endDay
        )

        var table: [String: [String: Any]] = [:]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let energyList = stats["energy"] as? [[String: Any]] ?? []
        for (idx, item) in energyList.enumerated() where idx < rangeDays {
            let day = Calendar.current.date(byAdding: .day, value: idx, to: startDay) ?? startDay
            let dayString = formatter.string(from: day)
            var entry = table[dayString] ?? ["date": dayString]

            if let value = item["energy"] {
                entry["solar_production"] = "\(value)"
            } else {
                entry["solar_production"] = NSNull()
            }

            table[dayString] = entry
        }

        return table
    }

    // MARK: - Device Charge Order Statistics

    func getDeviceChargeOrderStats(
        deviceSn: String,
        rangeType: String? = nil,
        startDay: Date? = nil,
        endDay: Date? = nil
    ) async throws -> [String: Any] {
        let range = ["week", "month", "year"].contains(rangeType ?? "") ? rangeType! : "all"
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let payload: [String: Any] = [
            "device_sn": deviceSn,
            "date_type": range,
            "start_date": (range == "all" || startDay == nil)
                ? "" : formatter.string(from: startDay!),
            "end_date": (range == "all" || endDay == nil) ? "" : formatter.string(from: endDay!),
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_device_charge_order_stats"] ?? "",
            json: payload
        )

        let data = (response["data"] as? [String: Any]) ?? [:]
        if let stats = data["total_stats"] as? [String: Any] {
            _ = api._update_dev(devData: ["device_sn": deviceSn, "total_stats": stats])
        }
        return data
    }
}

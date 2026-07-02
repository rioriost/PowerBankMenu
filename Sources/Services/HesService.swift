//
//  HesService.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/hesapi.py (core HES endpoints)
//
//  Notes:
//  - This is a minimal Swift port focused on primary endpoints and basic energy aggregation.
//  - Advanced cache/aggregation logic (avg power, intraday stats, conversions) can be added later.
//

import Foundation

final class HesService {
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

    // MARK: - System Running Info

    func getSystemRunningInfo(siteId: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["siteId": siteId]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.hesService["get_system_running_info"] ?? "",
            json: payload
        )

        let data = (response["data"] as? [String: Any]) ?? [:]

        if var site = api.sites[siteId] {
            var stats: [[String: String]] = []

            let totalEnergy =
                data["totalSystemPowerGeneration"] as? String
                ?? (data["totalSystemPowerGeneration"] != nil
                    ? String(describing: data["totalSystemPowerGeneration"]!)
                    : "")
            let totalEnergyUnit = (data["systemPowerGenerationUnit"] as? String ?? "").lowercased()

            let totalCarbon =
                data["saveCarbonFootprint"] as? String
                ?? (data["saveCarbonFootprint"] != nil
                    ? String(describing: data["saveCarbonFootprint"]!)
                    : "")
            let totalCarbonUnit = (data["saveCarbonUnit"] as? String ?? "").lowercased()

            let totalSavings =
                data["totalSystemSavings"] as? String
                ?? (data["totalSystemSavings"] != nil
                    ? String(describing: data["totalSystemSavings"]!)
                    : "")
            let totalSavingsUnit = data["systemSavingsPriceUnit"] as? String ?? ""

            stats.append(["type": "1", "total": totalEnergy, "unit": totalEnergyUnit])
            stats.append(["type": "2", "total": totalCarbon, "unit": totalCarbonUnit])
            stats.append(["type": "3", "total": totalSavings, "unit": totalSavingsUnit])

            var hesInfo = site["hes_info"] as? [String: Any] ?? [:]
            hesInfo["main_sn"] = data["mainSn"]
            hesInfo["main_pn"] = data["mainDeviceModel"]
            hesInfo["connected"] = data["connected"]
            hesInfo["numberOfParallelDevice"] = data["numberOfParallelDevice"]
            hesInfo["batCount"] = data["batCount"]
            hesInfo["rePostTime"] = data["rePostTime"]
            hesInfo["net"] = data["net"]
            hesInfo["realNet"] = data["realNet"]
            hesInfo["supportDiesel"] = data["supportDiesel"]
            hesInfo["isAddHeatPump"] = data["isAddHeatPump"]
            hesInfo["systemCode"] = data["systemCode"]
            hesInfo["emsDisable"] = data["emsDisable"]
            hesInfo["hasEvCharger"] = data["hasEvCharger"]
            hesInfo["evChargerInfos"] = data["evChargerInfos"]
            hesInfo["countryCode"] = data["countryCode"]
            hesInfo["mode"] = data["mode"]

            site["hes_info"] = hesInfo
            site["statistics"] = stats
            api.sites[siteId] = site

            if let mainSn = data["mainSn"] as? String {
                _ = api._update_dev(devData: [
                    "device_sn": mainSn,
                    "device_pn": data["mainDeviceModel"] as Any,
                ])
            }

            if let chargers = data["evChargerInfos"] as? [[String: Any]] {
                for charger in chargers {
                    _ = api._update_dev(
                        devData: [
                            "device_sn": charger["evChargerSn"] as Any,
                            "alias_name": charger["evChargerName"] as Any,
                            "ev_charger_status": charger["evChargerStatus"] as Any,
                        ],
                        siteId: siteId
                    )
                }
            }
        }

        return data
    }

    // MARK: - Energy Statistics

    func energyStatistics(
        siteId: String,
        rangeType: String? = nil,
        startDay: Date? = nil,
        endDay: Date? = nil,
        sourceType: String? = nil
    ) async throws -> [String: Any] {
        let range = ["day", "week", "year"].contains(rangeType ?? "") ? rangeType! : "day"
        let source =
            ["solar", "hes", "home", "grid"].contains(sourceType ?? "") ? sourceType! : "solar"

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let start = startDay ?? Date()
        let end = endDay ?? start

        let payload: [String: Any] = [
            "siteId": siteId,
            "sourceType": source,
            "dateType": range,
            "start": formatter.string(from: start),
            "end": formatter.string(from: end),
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.hesService["energy_statistics"] ?? "",
            json: payload
        )

        return (response["data"] as? [String: Any]) ?? [:]
    }

    // MARK: - Energy Daily (basic aggregation)

    func energyDaily(
        siteId: String,
        startDay: Date = Date(),
        numDays: Int = 1,
        dayTotals: Bool = false,
        devTypes: Set<String>? = nil,
        showProgress: Bool = false
    ) async throws -> [String: [String: Any]] {
        var table: [String: [String: Any]] = [:]
        let (start, rangeDays) = clampDays(startDay: startDay, numDays: numDays)

        var sources: [String] = ["solar"]
        if let devTypes, devTypes.contains(SolixDeviceType.hes.rawValue) {
            sources = ["solar", "hes", "home", "grid"]
        }

        for source in sources {
            let end = dayTotals ? start : addDays(start, rangeDays - 1)
            let resp = try await energyStatistics(
                siteId: siteId,
                rangeType: "week",
                startDay: start,
                endDay: end,
                sourceType: source
            )

            let items = resp["energy"] as? [[String: Any]] ?? []
            for idx in 0..<min(items.count, rangeDays) {
                let item = items[idx]
                let day = dayString(addDays(start, idx))
                let value = item["value"] ?? item["energy"] ?? item["total"] ?? NSNull()

                switch source {
                case "solar":
                    updateTable(&table, day: day, updates: ["solar_production": value])
                case "hes":
                    updateTable(&table, day: day, updates: ["battery_discharge": value])
                case "home":
                    updateTable(&table, day: day, updates: ["home_usage": value])
                case "grid":
                    updateTable(&table, day: day, updates: ["grid_import": value])
                default:
                    break
                }
            }

            if dayTotals {
                for idx in 0..<rangeDays {
                    let dayDate = addDays(start, idx)
                    let day = dayString(dayDate)
                    let dailyResp: [String: Any]
                    if idx == 0 {
                        dailyResp = resp
                    } else {
                        dailyResp = try await energyStatistics(
                            siteId: siteId,
                            rangeType: "week",
                            startDay: dayDate,
                            endDay: dayDate,
                            sourceType: source
                        )
                    }

                    let total =
                        dailyResp["totalEnergy"]
                        ?? dailyResp["total_energy"]
                        ?? dailyResp["totalExportedEnergy"]
                        ?? dailyResp["totalImportedEnergy"]

                    switch source {
                    case "solar":
                        updateTable(&table, day: day, updates: ["solar_total": total])
                    case "hes":
                        updateTable(&table, day: day, updates: ["battery_total": total])
                    case "home":
                        updateTable(&table, day: day, updates: ["home_total": total])
                    case "grid":
                        updateTable(&table, day: day, updates: ["grid_total": total])
                    default:
                        break
                    }

                    if showProgress {
                        api.logger("Received hes \(source) energy for \(day)")
                    }
                }
            }
        }

        return table
    }

    // MARK: - System Profit / Info

    func getSystemProfit(siteId: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["siteId": siteId]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.hesService["get_system_profit"] ?? "",
            json: payload
        )
        return (response["data"] as? [String: Any]) ?? [:]
    }

    func getProductInfo(siteId: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["siteId": siteId]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.hesService["get_product_info"] ?? "",
            json: payload
        )
        return (response["data"] as? [String: Any]) ?? [:]
    }

    func getHesDeviceInfo(siteId: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["siteId": siteId]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.hesService["get_hes_dev_info"] ?? "",
            json: payload
        )
        return (response["data"] as? [String: Any]) ?? [:]
    }

    func getHesWifiInfo(deviceSn: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["sn": deviceSn]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.hesService["get_wifi_info"] ?? "",
            json: payload
        )
        return (response["data"] as? [String: Any]) ?? [:]
    }
}

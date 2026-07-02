//
//  PowerPanelService.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/powerpanel.py (core PowerPanel endpoints)
//
//  Notes:
//  - This is a minimal Swift port focused on primary endpoints and basic energy aggregation.
//  - Advanced cache/aggregation logic (avg power, intraday stats, conversions) can be added later.
//

import Foundation

final class PowerPanelService {
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
            endpoint: ApiEndpoints.chargingService["get_system_running_info"] ?? "",
            json: payload
        )

        let data = (response["data"] as? [String: Any]) ?? [:]

        // Update sites cache with statistics (similar to Python)
        if var site = api.sites[siteId] {
            var stats: [[String: String]] = []

            let totalEnergy =
                data["total_system_power_generation"] as? String
                ?? (data["total_system_power_generation"] != nil
                    ? String(describing: data["total_system_power_generation"]!)
                    : "")
            let totalEnergyUnit = (data["system_power_generation_unit"] as? String ?? "")
                .lowercased()

            let totalCarbon =
                data["save_carbon_footprint"] as? String
                ?? (data["save_carbon_footprint"] != nil
                    ? String(describing: data["save_carbon_footprint"]!)
                    : "")
            let totalCarbonUnit = (data["save_carbon_unit"] as? String ?? "").lowercased()

            let totalSavings =
                data["total_system_savings"] as? String
                ?? (data["total_system_savings"] != nil
                    ? String(describing: data["total_system_savings"]!)
                    : "")
            let totalSavingsUnit = data["system_savings_price_unit"] as? String ?? ""

            stats.append(["type": "1", "total": totalEnergy, "unit": totalEnergyUnit])
            stats.append(["type": "2", "total": totalCarbon, "unit": totalCarbonUnit])
            stats.append(["type": "3", "total": totalSavings, "unit": totalSavingsUnit])

            site["statistics"] = stats
            site["connect_infos"] = data["connect_infos"] ?? [:]
            site["connected"] = data["connected"] ?? false
            api.sites[siteId] = site
        }

        return data
    }

    // MARK: - Energy Statistics

    func energyStatistics(
        siteId: String,
        rangeType: String? = nil,
        startDay: Date? = nil,
        endDay: Date? = nil,
        sourceType: String? = nil,
        isGlobal: Bool = false,
        productCode: String = ""
    ) async throws -> [String: Any] {
        let range = ["day", "week", "year"].contains(rangeType ?? "") ? rangeType! : "day"
        let source =
            ["solar", "hes", "home", "grid", "pps", "diesel"].contains(sourceType ?? "")
            ? sourceType! : "solar"

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
            "global": isGlobal,
            "productCode": productCode,
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.chargingService["energy_statistics"] ?? "",
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
        if let devTypes, devTypes.contains(SolixDeviceType.powerpanel.rawValue) {
            sources = ["solar", "hes", "home", "grid", "pps", "diesel"]
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
                case "hes", "pps":
                    updateTable(&table, day: day, updates: ["battery_discharge": value])
                case "home":
                    updateTable(&table, day: day, updates: ["home_usage": value])
                case "grid":
                    updateTable(&table, day: day, updates: ["grid_import": value])
                case "diesel":
                    updateTable(&table, day: day, updates: ["diesel_usage": value])
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
                    case "hes", "pps":
                        updateTable(&table, day: day, updates: ["battery_total": total])
                    case "home":
                        updateTable(&table, day: day, updates: ["home_total": total])
                    case "grid":
                        updateTable(&table, day: day, updates: ["grid_total": total])
                    case "diesel":
                        updateTable(&table, day: day, updates: ["diesel_total": total])
                    default:
                        break
                    }

                    if showProgress {
                        api.logger("Received powerpanel \(source) energy for \(day)")
                    }
                }
            }
        }

        return table
    }
}

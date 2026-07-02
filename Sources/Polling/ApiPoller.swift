//
//  ApiPoller.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/poller.py (simplified cache refresh)
//

import Foundation

struct ApiPoller {
    private static func nowString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }

    private static func extractSiteList(from response: [String: Any]) -> [[String: Any]] {
        if let data = response["data"] as? [String: Any],
            let list = data["site_list"] as? [[String: Any]]
        {
            return list
        }
        if let list = response["site_list"] as? [[String: Any]] {
            return list
        }
        return []
    }

    private static func extractScene(from response: [String: Any]) -> [String: Any] {
        if let data = response["data"] as? [String: Any] {
            return data
        }
        return response
    }

    private static func extractPayload(from response: [String: Any]) -> Any? {
        return response["data"] ?? response["payload"] ?? response["result"] ?? response["body"]
    }

    private static func startOfDay(_ date: Date = Date()) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private static func addDays(_ date: Date, _ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }

    private static func updateSiteType(site: inout [String: Any], siteInfo: [String: Any]) {
        if let powerSiteType = siteInfo["power_site_type"] as? Int,
            let mapped = SolixSiteType.map[powerSiteType]
        {
            site["site_type"] = mapped
        }
    }

    private static func addDevices(
        api: SolixApi,
        siteId: String,
        siteAdmin: Bool,
        devType: SolixDeviceType,
        list: [[String: Any]]
    ) {
        for item in list {
            guard let sn = item["device_sn"] as? String, !sn.isEmpty else { continue }
            var devData = item
            devData["device_sn"] = sn
            devData["site_id"] = siteId
            _ = api._update_dev(
                devData: devData,
                devType: devType.rawValue,
                siteId: siteId,
                isAdmin: siteAdmin
            )
            api.addSiteDevice(sn)
        }
    }

    private static func updateDevicesFromScene(
        api: SolixApi,
        siteId: String,
        siteAdmin: Bool,
        scene: [String: Any]
    ) {
        if let solarbankInfo = scene["solarbank_info"] as? [String: Any],
            let list = solarbankInfo["solarbank_list"] as? [[String: Any]]
        {
            addDevices(
                api: api, siteId: siteId, siteAdmin: siteAdmin, devType: .solarbank, list: list)
        }

        if let ppsInfo = scene["pps_info"] as? [String: Any],
            let list = ppsInfo["pps_list"] as? [[String: Any]]
        {
            addDevices(api: api, siteId: siteId, siteAdmin: siteAdmin, devType: .pps, list: list)
        }

        if let list = scene["solar_list"] as? [[String: Any]] {
            addDevices(
                api: api, siteId: siteId, siteAdmin: siteAdmin, devType: .inverter, list: list)
        }

        if let gridInfo = scene["grid_info"] as? [String: Any],
            let list = gridInfo["grid_list"] as? [[String: Any]]
        {
            addDevices(
                api: api, siteId: siteId, siteAdmin: siteAdmin, devType: .smartmeter, list: list)
        }

        if let smartPlugInfo = scene["smart_plug_info"] as? [String: Any],
            let list = smartPlugInfo["smartplug_list"] as? [[String: Any]]
        {
            addDevices(
                api: api, siteId: siteId, siteAdmin: siteAdmin, devType: .smartplug, list: list)
        }

        if let list = scene["powerpanel_list"] as? [[String: Any]] {
            addDevices(
                api: api, siteId: siteId, siteAdmin: siteAdmin, devType: .powerpanel, list: list)
        }
    }

    // MARK: - Poll Sites

    @discardableResult
    static func pollSites(
        api: SolixApi,
        siteId: String? = nil,
        fromFile: Bool = false,
        exclude: Set<String>? = nil
    ) async throws -> [String: [String: Any]] {
        let excludeSet = exclude ?? []
        let start = Date()

        if siteId == nil {
            api.resetSiteDevices()
        }

        let listResponse = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["site_list"] ?? "",
            json: [:]
        )

        var siteList = extractSiteList(from: listResponse)
        if let siteId {
            siteList = siteList.filter { ($0["site_id"] as? String) == siteId }
        }

        var activeSites = Set<String>()

        for siteItem in siteList {
            guard let id = siteItem["site_id"] as? String else { continue }
            activeSites.insert(id)

            var site = api.sites[id] ?? [:]
            var siteInfo = site["site_info"] as? [String: Any] ?? [:]
            siteInfo.merge(siteItem) { _, new in new }
            site["site_info"] = siteInfo
            site["type"] = SolixDeviceType.system.rawValue
            updateSiteType(site: &site, siteInfo: siteInfo)

            let admin = (siteInfo["ms_type"] as? Int ?? 0) <= 1
            site["site_admin"] = admin
            api.sites[id] = site

            if site["site_type"] as? String == SolixDeviceType.virtual.rawValue {
                continue
            }

            let sceneResponse = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["scene_info"] ?? "",
                json: ["site_id": id]
            )

            let scene = extractScene(from: sceneResponse)
            var updatedSite = api.sites[id] ?? [:]
            updatedSite.merge(scene) { _, new in new }
            api.sites[id] = updatedSite

            if !excludeSet.contains(ApiCategories.mqttDevices) {
                updateDevicesFromScene(
                    api: api,
                    siteId: id,
                    siteAdmin: admin,
                    scene: scene
                )
            }
        }

        if siteId == nil {
            api.recycleSites(activeSites: activeSites)
            api.recycleDevices(activeDevices: api.currentSiteDevices())
        }

        api._update_account(details: [
            "use_files": fromFile,
            "sites_poll_time": nowString(),
            "sites_poll_seconds": round(Date().timeIntervalSince(start) * 1000) / 1000,
        ])

        return api.sites
    }

    // MARK: - Poll Site Details (lightweight)

    @discardableResult
    static func pollSiteDetails(
        api: SolixApi,
        fromFile: Bool = false,
        exclude: Set<String>? = nil
    ) async throws -> [String: [String: Any]] {
        let excludeSet = exclude ?? []
        let start = Date()

        if !excludeSet.contains(ApiCategories.accountInfo) {
            let response = try await api.request(
                method: "GET",
                endpoint: ApiEndpoints.powerService["get_message_unread"] ?? "",
                json: [:]
            )
            if let payload = extractPayload(from: response) {
                api._update_account(details: ["message_unread": payload])
            }
        }

        if !excludeSet.contains(ApiCategories.accountInfo) {
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["get_config"] ?? "",
                json: [:]
            )
            if let payload = extractPayload(from: response) {
                api._update_account(details: ["config": payload])
            }
        }

        for (siteId, site) in api.sites {
            let isAdmin = site["site_admin"] as? Bool ?? false

            if isAdmin {
                let detailResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["site_detail"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: detailResponse) {
                    if let detailData = payload as? [String: Any], !detailData.isEmpty {
                        api._update_site(siteId: siteId, details: detailData)
                    } else {
                        api._update_site(siteId: siteId, details: ["site_detail": payload])
                    }
                }

                let rulesResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["site_rules"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: rulesResponse) {
                    api._update_site(siteId: siteId, details: ["site_rules": payload])
                }

                let powerLimitResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_site_power_limit"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: powerLimitResponse) {
                    api._update_site(siteId: siteId, details: ["site_power_limit": payload])
                }

                let forecastResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_forecast_schedule"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: forecastResponse) {
                    api._update_site(siteId: siteId, details: ["forecast_schedule": payload])
                }

                let co2Response = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_co2_ranking"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: co2Response) {
                    api._update_site(siteId: siteId, details: ["co2_ranking": payload])
                }

                let installationResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_installation"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: installationResponse) {
                    api._update_site(siteId: siteId, details: ["installation": payload])
                }
            }

            if isAdmin && !excludeSet.contains(ApiCategories.sitePrice) {
                let response = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_site_price"] ?? "",
                    json: ["site_id": siteId]
                )
                if let payload = extractPayload(from: response) {
                    api._update_site(siteId: siteId, details: ["site_price": payload])
                }
            }
        }

        api._update_account(details: [
            "site_details_poll_time": nowString(),
            "site_details_poll_seconds": round(Date().timeIntervalSince(start) * 1000) / 1000,
            "use_files": fromFile,
        ])

        return api.sites
    }

    // MARK: - Poll Device Details (lightweight)

    @discardableResult
    static func pollDeviceDetails(
        api: SolixApi,
        fromFile: Bool = false,
        exclude: Set<String>? = nil
    ) async throws -> [String: [String: Any]] {
        let excludeSet = exclude ?? []

        let bindResponse = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["bind_devices"] ?? "",
            json: [:]
        )

        if !excludeSet.contains(ApiCategories.deviceAutoUpgrade) {
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["get_auto_upgrade"] ?? "",
                json: [:]
            )
            let data = (response["data"] as? [String: Any]) ?? [:]
            let mainSwitch = data["main_switch"] as? Bool
            let deviceList = data["device_list"] as? [[String: Any]] ?? []

            for item in deviceList {
                var update = item
                if let mainSwitch, let autoUpgrade = item["auto_upgrade"] as? Bool {
                    update["auto_upgrade"] = mainSwitch && autoUpgrade
                }
                _ = api._update_dev(devData: update)
            }
        }

        let payload = (bindResponse["data"] as? [String: Any]) ?? bindResponse
        var deviceList: [[String: Any]] = []
        if let list = payload["device_list"] as? [[String: Any]] {
            deviceList = list
            for item in list {
                _ = api._update_dev(devData: item)
            }
        } else if let list = payload["data"] as? [[String: Any]] {
            deviceList = list
            for item in list {
                _ = api._update_dev(devData: item)
            }
        }

        if deviceList.isEmpty {
            deviceList = Array(api.devices.values)
        }

        for item in deviceList {
            guard let sn = item["device_sn"] as? String, !sn.isEmpty else { continue }
            let siteId = (item["site_id"] as? String) ?? (api.devices[sn]?["site_id"] as? String)
            let isAdmin =
                (item["is_admin"] as? Bool)
                ?? (api.devices[sn]?["is_admin"] as? Bool)
                ?? false

            if !isAdmin {
                continue
            }

            if !excludeSet.contains(ApiCategories.deviceTag) {
                let attrsResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_device_attributes"] ?? "",
                    json: ["device_sn": sn, "attributes": []]
                )
                if let payload = extractPayload(from: attrsResponse) {
                    _ = api._update_dev(devData: ["device_sn": sn, "device_attrs": payload])
                }

                var fittingsJson: [String: Any] = ["device_sn": sn]
                if let siteId { fittingsJson["site_id"] = siteId }
                let fittingsResponse = try await api.request(
                    method: "POST",
                    endpoint: ApiEndpoints.powerService["get_device_fittings"] ?? "",
                    json: fittingsJson
                )
                if let payload = extractPayload(from: fittingsResponse) {
                    let normalized =
                        (payload as? [String: Any])?["data"]
                        ?? payload
                    _ = api._update_dev(devData: ["device_sn": sn, "device_fittings": normalized])
                }
            }

            if !excludeSet.contains(ApiCategories.deviceAutoUpgrade) {
                var deviceType =
                    (api.devices[sn]?["type"] as? String)
                    ?? (item["type"] as? String)
                    ?? ""
                if deviceType.isEmpty {
                    let pn =
                        (api.devices[sn]?["device_pn"] as? String)
                        ?? (item["device_pn"] as? String)
                        ?? (item["product_code"] as? String)
                        ?? ""
                    if let mapped = SolixDeviceCategory.map[pn] {
                        let parts = mapped.split(separator: "_")
                        if let last = parts.last, Int(last) != nil, parts.count > 1 {
                            deviceType = parts.dropLast().joined(separator: "_")
                        } else {
                            deviceType = mapped
                        }
                    }
                }
                var otaInfoJson: [String: Any]?
                if deviceType == SolixDeviceType.solarbank.rawValue {
                    otaInfoJson = ["solar_bank_sn": sn]
                } else if deviceType == SolixDeviceType.inverter.rawValue {
                    otaInfoJson = ["solar_sn": sn]
                }

                if let otaInfoJson {
                    let otaInfoResponse = try await api.request(
                        method: "POST",
                        endpoint: ApiEndpoints.powerService["get_ota_info"] ?? "",
                        json: otaInfoJson
                    )
                    if let payload = extractPayload(from: otaInfoResponse) {
                        _ = api._update_dev(devData: ["device_sn": sn, "ota_info": payload])
                    }
                }

                if deviceType == SolixDeviceType.solarbank.rawValue {
                    let otaUpdateResponse = try await api.request(
                        method: "POST",
                        endpoint: ApiEndpoints.powerService["get_ota_update"] ?? "",
                        json: ["device_sn": sn, "insert_sn": ""]
                    )
                    if let payload = extractPayload(from: otaUpdateResponse) {
                        _ = api._update_dev(devData: ["device_sn": sn, "ota_update": payload])
                    }
                }

                if deviceType == SolixDeviceType.solarbank.rawValue {
                    let upgradeRecordResponse = try await api.request(
                        method: "POST",
                        endpoint: ApiEndpoints.powerService["get_upgrade_record"] ?? "",
                        json: ["device_sn": sn, "type": 1]
                    )
                    if let payload = extractPayload(from: upgradeRecordResponse) {
                        _ = api._update_dev(devData: ["device_sn": sn, "upgrade_record": payload])
                    }

                    let checkUpgradeResponse = try await api.request(
                        method: "POST",
                        endpoint: ApiEndpoints.powerService["check_upgrade_record"] ?? "",
                        json: ["type": 1]
                    )
                    if let payload = extractPayload(from: checkUpgradeResponse) {
                        _ = api._update_dev(devData: [
                            "device_sn": sn, "upgrade_record_checked": payload,
                        ])
                    }
                }
            }
        }

        api._update_account(details: [
            "device_details_poll_time": nowString(),
            "use_files": fromFile,
        ])
        return api.devices
    }

    // MARK: - Poll Device Energy (detailed)

    @discardableResult
    static func pollDeviceEnergy(
        api: SolixApi,
        fromFile: Bool = false,
        exclude: Set<String>? = nil
    ) async throws -> [String: [String: Any]] {
        let excludeSet = exclude ?? []
        let start = Date()

        guard let energyService = api.energyService else {
            return api.sites
        }

        let today = startOfDay()
        let yesterday = addDays(today, -1)

        for (siteId, site) in api.sites {
            var updatedSite = api.sites[siteId] ?? site
            var energyDetails = updatedSite["energy_details"] as? [String: Any] ?? [:]
            var deviceDetails = energyDetails["devices"] as? [String: Any] ?? [:]
            var deviceToday = deviceDetails["today"] as? [String: Any] ?? [:]
            var deviceYesterday = deviceDetails["yesterday"] as? [String: Any] ?? [:]
            var systemDetails = energyDetails["systems"] as? [String: Any] ?? [:]
            var todaySummary = energyDetails["today"] as? [String: Any] ?? [:]
            var yesterdaySummary = energyDetails["yesterday"] as? [String: Any] ?? [:]
            var fallbackToday: [String: Any]?
            var fallbackYesterday: [String: Any]?

            let extractSeriesValues: ([String: Any]) -> [Double] = { payload in
                let rawSeries =
                    (payload["power"] as? [[String: Any]])
                    ?? (payload["energy"] as? [[String: Any]])
                    ?? (payload["list"] as? [[String: Any]])
                    ?? (payload["data"] as? [[String: Any]])
                    ?? []
                let unitRaw =
                    (payload["unit"] as? String)
                    ?? (payload["power_unit"] as? String)
                    ?? (payload["dataUnit"] as? String)
                    ?? (payload["data_unit"] as? String)
                    ?? ""
                let unit = unitRaw.lowercased()
                let scale: Double = unit == "kw" ? 1000 : 1
                var values: [Double] = []
                for item in rawSeries {
                    let candidates: [Any?] = [
                        item["value"], item["power"], item["total"], item["energy"],
                    ]
                    for candidate in candidates {
                        if let value = candidate as? Double {
                            if value.isFinite { values.append(value * scale) }
                            break
                        } else if let value = candidate as? Int {
                            values.append(Double(value) * scale)
                            break
                        } else if let value = candidate as? String, let parsed = Double(value) {
                            if parsed.isFinite { values.append(parsed * scale) }
                            break
                        }
                    }
                }
                return values
            }

            let updateEnergy: (String, Set<String>, String?, String?) async throws -> Void = {
                deviceSn, devTypes, category, deviceType in
                if let category, excludeSet.contains(category) {
                    return
                }

                let todayTable = try await energyService.energyDaily(
                    siteId: siteId,
                    deviceSn: deviceSn,
                    startDay: today,
                    numDays: 1,
                    dayTotals: true,
                    devTypes: devTypes,
                    showProgress: false
                )
                let todayData = todayTable.values.first ?? [:]
                var taggedToday = todayData
                taggedToday["device_sn"] = deviceSn
                if let deviceType { taggedToday["device_type"] = deviceType }
                taggedToday["site_id"] = siteId
                deviceToday[deviceSn] = taggedToday
                if fallbackToday == nil, !todayData.isEmpty {
                    fallbackToday = todayData
                }

                let yesterdayTable = try await energyService.energyDaily(
                    siteId: siteId,
                    deviceSn: deviceSn,
                    startDay: yesterday,
                    numDays: 1,
                    dayTotals: true,
                    devTypes: devTypes,
                    showProgress: false
                )
                let yesterdayData = yesterdayTable.values.first ?? [:]
                var taggedYesterday = yesterdayData
                taggedYesterday["device_sn"] = deviceSn
                if let deviceType { taggedYesterday["device_type"] = deviceType }
                taggedYesterday["site_id"] = siteId
                deviceYesterday[deviceSn] = taggedYesterday
                if fallbackYesterday == nil, !yesterdayData.isEmpty {
                    fallbackYesterday = yesterdayData
                }
            }

            let solarbankList =
                (site["solarbank_info"] as? [String: Any])?["solarbank_list"] as? [[String: Any]]
                ?? []
            for item in solarbankList {
                guard let sn = item["device_sn"] as? String, !sn.isEmpty else { continue }
                try await updateEnergy(
                    sn,
                    Set([SolixDeviceType.solarbank.rawValue]),
                    ApiCategories.solarbankEnergy,
                    SolixDeviceType.solarbank.rawValue
                )
            }

            let smartmeterList =
                (site["grid_info"] as? [String: Any])?["grid_list"] as? [[String: Any]] ?? []
            for item in smartmeterList {
                guard let sn = item["device_sn"] as? String, !sn.isEmpty else { continue }
                try await updateEnergy(
                    sn,
                    Set([SolixDeviceType.smartmeter.rawValue]),
                    ApiCategories.smartmeterEnergy,
                    SolixDeviceType.smartmeter.rawValue
                )
            }

            let smartplugList =
                (site["smart_plug_info"] as? [String: Any])?["smartplug_list"] as? [[String: Any]]
                ?? []
            for item in smartplugList {
                guard let sn = item["device_sn"] as? String, !sn.isEmpty else { continue }
                try await updateEnergy(
                    sn,
                    Set([SolixDeviceType.smartplug.rawValue]),
                    ApiCategories.smartplugEnergy,
                    SolixDeviceType.smartplug.rawValue
                )
            }

            let inverterList = site["solar_list"] as? [[String: Any]] ?? []
            for item in inverterList {
                guard let sn = item["device_sn"] as? String, !sn.isEmpty else { continue }
                try await updateEnergy(
                    sn,
                    Set([SolixDeviceType.inverter.rawValue]),
                    ApiCategories.solarEnergy,
                    SolixDeviceType.inverter.rawValue
                )
            }

            let powerpanelList = site["powerpanel_list"] as? [[String: Any]] ?? []
            let hasPowerpanel =
                !powerpanelList.isEmpty
                || (site["site_type"] as? String) == SolixDeviceType.powerpanel.rawValue
            if hasPowerpanel,
                let powerPanelService = api.powerPanelService,
                !excludeSet.contains(ApiCategories.powerpanelEnergy)
            {
                var powerpanelDetails = systemDetails["powerpanel"] as? [String: Any] ?? [:]
                let todayTable = try await powerPanelService.energyDaily(
                    siteId: siteId,
                    startDay: today,
                    numDays: 1,
                    dayTotals: true,
                    devTypes: Set([SolixDeviceType.powerpanel.rawValue]),
                    showProgress: false
                )
                let todayData = todayTable.values.first ?? [:]
                if !todayData.isEmpty {
                    var taggedToday = todayData
                    taggedToday["site_id"] = siteId
                    taggedToday["system_type"] = SolixDeviceType.powerpanel.rawValue
                    powerpanelDetails["today"] = taggedToday
                    if fallbackToday == nil { fallbackToday = todayData }
                }

                let yesterdayTable = try await powerPanelService.energyDaily(
                    siteId: siteId,
                    startDay: yesterday,
                    numDays: 1,
                    dayTotals: true,
                    devTypes: Set([SolixDeviceType.powerpanel.rawValue]),
                    showProgress: false
                )
                let yesterdayData = yesterdayTable.values.first ?? [:]
                if !yesterdayData.isEmpty {
                    var taggedYesterday = yesterdayData
                    taggedYesterday["site_id"] = siteId
                    taggedYesterday["system_type"] = SolixDeviceType.powerpanel.rawValue
                    powerpanelDetails["yesterday"] = taggedYesterday
                    if fallbackYesterday == nil { fallbackYesterday = yesterdayData }
                }

                if !excludeSet.contains(ApiCategories.powerpanelAvgPower) {
                    var hourly = powerpanelDetails["hourly"] as? [String: Any] ?? [:]
                    var avgPower = powerpanelDetails["avg_power"] as? [String: Any] ?? [:]
                    let sources = ["solar", "hes", "home", "grid", "pps", "diesel"]

                    for day in [today, yesterday] {
                        let dayKeyValue = dayKey(day)
                        var dayHourly = hourly[dayKeyValue] as? [String: Any] ?? [:]
                        var dayAvg = avgPower[dayKeyValue] as? [String: Any] ?? [:]

                        for source in sources {
                            let hourlyPayload = try await powerPanelService.energyStatistics(
                                siteId: siteId,
                                rangeType: "day",
                                startDay: day,
                                endDay: day,
                                sourceType: source
                            )
                            dayHourly[source] = hourlyPayload
                            if let avg = average(extractSeriesValues(hourlyPayload)) {
                                dayAvg[source] = avg
                            }
                        }

                        hourly[dayKeyValue] = dayHourly
                        avgPower[dayKeyValue] = dayAvg
                    }

                    powerpanelDetails["hourly"] = hourly
                    powerpanelDetails["avg_power"] = avgPower
                }

                systemDetails["powerpanel"] = powerpanelDetails
            }

            let hasHes =
                (site["site_type"] as? String) == SolixDeviceType.hes.rawValue
                || (site["hes_info"] as? [String: Any]) != nil
            if hasHes,
                let hesService = api.hesService,
                !excludeSet.contains(ApiCategories.hesEnergy)
            {
                var hesDetails = systemDetails["hes"] as? [String: Any] ?? [:]
                let todayTable = try await hesService.energyDaily(
                    siteId: siteId,
                    startDay: today,
                    numDays: 1,
                    dayTotals: true,
                    devTypes: Set([SolixDeviceType.hes.rawValue]),
                    showProgress: false
                )
                let todayData = todayTable.values.first ?? [:]
                if !todayData.isEmpty {
                    var taggedToday = todayData
                    taggedToday["site_id"] = siteId
                    taggedToday["system_type"] = SolixDeviceType.hes.rawValue
                    hesDetails["today"] = taggedToday
                    if fallbackToday == nil { fallbackToday = todayData }
                }

                let yesterdayTable = try await hesService.energyDaily(
                    siteId: siteId,
                    startDay: yesterday,
                    numDays: 1,
                    dayTotals: true,
                    devTypes: Set([SolixDeviceType.hes.rawValue]),
                    showProgress: false
                )
                let yesterdayData = yesterdayTable.values.first ?? [:]
                if !yesterdayData.isEmpty {
                    var taggedYesterday = yesterdayData
                    taggedYesterday["site_id"] = siteId
                    taggedYesterday["system_type"] = SolixDeviceType.hes.rawValue
                    hesDetails["yesterday"] = taggedYesterday
                    if fallbackYesterday == nil { fallbackYesterday = yesterdayData }
                }

                if !excludeSet.contains(ApiCategories.hesAvgPower) {
                    var hourly = hesDetails["hourly"] as? [String: Any] ?? [:]
                    var avgPower = hesDetails["avg_power"] as? [String: Any] ?? [:]
                    let sources = ["solar", "hes", "home", "grid"]

                    for day in [today, yesterday] {
                        let dayKeyValue = dayKey(day)
                        var dayHourly = hourly[dayKeyValue] as? [String: Any] ?? [:]
                        var dayAvg = avgPower[dayKeyValue] as? [String: Any] ?? [:]

                        for source in sources {
                            let hourlyPayload = try await hesService.energyStatistics(
                                siteId: siteId,
                                rangeType: "day",
                                startDay: day,
                                endDay: day,
                                sourceType: source
                            )
                            dayHourly[source] = hourlyPayload
                            if let avg = average(extractSeriesValues(hourlyPayload)) {
                                dayAvg[source] = avg
                            }
                        }

                        hourly[dayKeyValue] = dayHourly
                        avgPower[dayKeyValue] = dayAvg
                    }

                    hesDetails["hourly"] = hourly
                    hesDetails["avg_power"] = avgPower
                }

                systemDetails["hes"] = hesDetails
            }

            if todaySummary.isEmpty, let fallbackToday {
                todaySummary = fallbackToday
            }
            if yesterdaySummary.isEmpty, let fallbackYesterday {
                yesterdaySummary = fallbackYesterday
            }

            deviceDetails["today"] = deviceToday
            deviceDetails["yesterday"] = deviceYesterday
            energyDetails["devices"] = deviceDetails
            energyDetails["systems"] = systemDetails
            energyDetails["today"] = todaySummary
            energyDetails["yesterday"] = yesterdaySummary
            updatedSite["energy_details"] = energyDetails
            api.sites[siteId] = updatedSite
        }

        api._update_account(details: [
            "energy_poll_time": nowString(),
            "energy_poll_seconds": round(Date().timeIntervalSince(start) * 1000) / 1000,
            "use_files": fromFile,
        ])
        return api.sites
    }
}

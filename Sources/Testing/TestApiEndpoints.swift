//
//  TestApiEndpoints.swift
//  PowerBankMenu
//
//  API endpoint test harness for ticket 19
//

import Foundation

struct TestApiEndpoints {
    struct Input {
        let email: String
        let password: String
        let countryId: String
        let verbose: Bool

        init(
            email: String,
            password: String,
            countryId: String = "US",
            verbose: Bool = true
        ) {
            self.email = email
            self.password = password
            self.countryId = countryId
            self.verbose = verbose
        }
    }

    static func run(_ input: Input) async -> Bool {
        do {
            let api = try SolixApi(
                email: input.email,
                password: input.password,
                countryId: input.countryId
            )

            if input.verbose {
                print("Testing Solix API: endpoint requests")
            }

            _ = try await api.asyncAuthenticate()

            // Ensure at least one site/device is loaded for endpoint tests.
            _ = try await ApiPoller.pollSites(api: api)
            _ = try await ApiPoller.pollDeviceDetails(api: api)

            let firstSite = api.sites.values.first
            let siteId =
                (firstSite?["site_info"] as? [String: Any])?["site_id"] as? String
            if siteId == nil {
                print("No site found for endpoint tests. Running account-only endpoints.")
            }

            let firstDevice = api.devices.values.first
            let deviceSn = firstDevice?["device_sn"] as? String
            let deviceType = firstDevice?["type"] as? String

            let endpointResults: [(String, [String: Any])] = try await [
                (
                    "get_message_unread",
                    api.request(
                        method: "GET",
                        endpoint: ApiEndpoints.powerService["get_message_unread"] ?? "",
                        json: [:])
                ),
                (
                    "homepage",
                    api.request(
                        method: "POST", endpoint: ApiEndpoints.powerService["homepage"] ?? "",
                        json: [:])
                ),
                (
                    "site_list",
                    api.request(
                        method: "POST", endpoint: ApiEndpoints.powerService["site_list"] ?? "",
                        json: [:])
                ),
                (
                    "bind_devices",
                    api.request(
                        method: "POST", endpoint: ApiEndpoints.powerService["bind_devices"] ?? "",
                        json: [:])
                ),
                (
                    "user_devices",
                    api.request(
                        method: "POST", endpoint: ApiEndpoints.powerService["user_devices"] ?? "",
                        json: [:])
                ),
                (
                    "charging_devices",
                    api.request(
                        method: "POST",
                        endpoint: ApiEndpoints.powerService["charging_devices"] ?? "", json: [:])
                ),
                (
                    "get_auto_upgrade",
                    api.request(
                        method: "POST",
                        endpoint: ApiEndpoints.powerService["get_auto_upgrade"] ?? "", json: [:])
                ),
            ]

            var extraResults: [(String, [String: Any])] = []

            if let siteId {
                extraResults.append(
                    (
                        "site_detail",
                        try await api.request(
                            method: "POST",
                            endpoint: ApiEndpoints.powerService["site_detail"] ?? "",
                            json: ["site_id": siteId])
                    ))
                extraResults.append(
                    (
                        "wifi_list",
                        try await api.request(
                            method: "POST", endpoint: ApiEndpoints.powerService["wifi_list"] ?? "",
                            json: ["site_id": siteId])
                    ))
                extraResults.append(
                    (
                        "get_site_price",
                        try await api.request(
                            method: "POST",
                            endpoint: ApiEndpoints.powerService["get_site_price"] ?? "",
                            json: ["site_id": siteId, "accuracy": 5])
                    ))
            }

            if let deviceSn {
                let isSolarbank = deviceType == SolixDeviceType.solarbank.rawValue
                if let siteId {
                    if isSolarbank {
                        extraResults.append(
                            (
                                "solar_info",
                                try await api.request(
                                    method: "POST",
                                    endpoint: ApiEndpoints.powerService["solar_info"] ?? "",
                                    json: ["site_id": siteId, "solarbank_sn": deviceSn]
                                )
                            ))
                        extraResults.append(
                            (
                                "get_cutoff",
                                try await api.request(
                                    method: "POST",
                                    endpoint: ApiEndpoints.powerService["get_cutoff"] ?? "",
                                    json: ["site_id": siteId, "device_sn": deviceSn]
                                )
                            ))
                    }
                    extraResults.append(
                        (
                            "get_device_fittings",
                            try await api.request(
                                method: "POST",
                                endpoint: ApiEndpoints.powerService["get_device_fittings"] ?? "",
                                json: ["site_id": siteId, "device_sn": deviceSn]
                            )
                        ))
                    extraResults.append(
                        (
                            "get_device_load",
                            try await api.request(
                                method: "POST",
                                endpoint: ApiEndpoints.powerService["get_device_load"] ?? "",
                                json: ["site_id": siteId, "device_sn": deviceSn]
                            )
                        ))
                }
                if isSolarbank {
                    extraResults.append(
                        (
                            "compatible_process",
                            try await api.request(
                                method: "POST",
                                endpoint: ApiEndpoints.powerService["compatible_process"] ?? "",
                                json: ["solarbank_sn": deviceSn]
                            )
                        )
                    )
                }
            }

            if let siteId {
                extraResults.append(
                    (
                        "get_device_parm",
                        try await api.request(
                            method: "POST",
                            endpoint: ApiEndpoints.powerService["get_device_parm"] ?? "",
                            json: ["site_id": siteId, "param_type": "4"]
                        )
                    ))
                extraResults.append(
                    (
                        "home_load_chart",
                        try await api.request(
                            method: "POST",
                            endpoint: ApiEndpoints.powerService["home_load_chart"] ?? "",
                            json: ["site_id": siteId]
                        )
                    ))
            }

            if input.verbose {
                for (name, response) in endpointResults + extraResults {
                    print("Endpoint \(name):")
                    print(prettyJSON(response))
                }
            }

            return true
        } catch {
            print("Endpoint test failed: \(error)")
            return false
        }
    }

    private static func prettyJSON(_ object: Any) -> String {
        guard JSONSerialization.isValidJSONObject(object),
            let data = try? JSONSerialization.data(
                withJSONObject: object, options: [.prettyPrinted]),
            let text = String(data: data, encoding: .utf8)
        else {
            return "\(object)"
        }
        return text
    }
}

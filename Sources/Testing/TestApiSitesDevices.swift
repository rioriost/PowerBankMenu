//
//  TestApiSitesDevices.swift
//  PowerBankMenu
//
//  Site/device polling test harness for ticket 19
//

import Foundation

struct TestApiSitesDevices {
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
            var config = ApiSessionConfiguration()
            config.logger = { message in
                print(message)
            }
            let session = try ApiSession(
                email: input.email,
                password: input.password,
                countryId: input.countryId,
                configuration: config
            )
            let api = try SolixApi(apisession: session)

            if input.verbose {
                print("Testing Solix API: sites/devices polling")
            }

            _ = try await api.asyncAuthenticate()

            _ = try await ApiPoller.pollSites(api: api)
            _ = try await ApiPoller.pollDeviceDetails(api: api)
            _ = try await ApiPoller.pollSiteDetails(api: api)
            _ = try await ApiPoller.pollDeviceEnergy(api: api)

            if input.verbose {
                print("Account Overview:")
                print(prettyJSON(api.account))
                print("System Overview:")
                print(prettyJSON(api.sites))
                print("Device Overview:")
                print(prettyJSON(api.devices))
            }

            return true
        } catch {
            print("Sites/devices test failed: \(error)")
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

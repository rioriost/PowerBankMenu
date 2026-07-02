//
//  TestIntegrationRunner.swift
//  PowerBankMenu
//
//  Integrated ticket 19 test flow runner
//

import Foundation

struct TestIntegrationRunner {
    struct Input {
        let email: String
        let password: String
        let countryId: String
        let deviceSn: String?

        init(
            email: String,
            password: String,
            countryId: String = "US",
            deviceSn: String? = nil
        ) {
            self.email = email
            self.password = password
            self.countryId = countryId
            self.deviceSn = deviceSn
        }
    }

    static func run(_ input: Input) async {
        let email = input.email
        let password = input.password
        let country = input.countryId
        let deviceSn = input.deviceSn

        guard !email.isEmpty, !password.isEmpty else {
            print("Missing credentials. Provide email and password.")
            return
        }

        print("=== Ticket 19 Integration Test Start ===")

        let loginOk = await TestApiLogin.run(
            .init(email: email, password: password, countryId: country, verbose: true)
        )
        guard loginOk else {
            print("Login test failed. Aborting.")
            return
        }

        let sitesOk = await TestApiSitesDevices.run(
            .init(email: email, password: password, countryId: country, verbose: true)
        )
        guard sitesOk else {
            print("Sites/devices test failed. Aborting.")
            return
        }

        let endpointsOk = await TestApiEndpoints.run(
            .init(email: email, password: password, countryId: country, verbose: true)
        )
        guard endpointsOk else {
            print("Endpoint test failed. Aborting.")
            return
        }

        let mqttOk = await TestMqttMonitor.run(
            .init(
                email: email,
                password: password,
                countryId: country,
                deviceSn: deviceSn,
                realtimeTrigger: true,
                statusRequest: false,
                runtimeSeconds: 60,
                verbose: true
            )
        )
        if !mqttOk {
            print("MQTT monitor test failed.")
            return
        }

        print("=== Ticket 19 Integration Test Completed ===")
    }
}

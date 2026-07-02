//
//  TestApiLogin.swift
//  PowerBankMenu
//
//  Login test harness mirroring Python test_api authentication flow
//

import Foundation

struct TestApiLogin {
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
                print("Testing Solix API: login")
            }

            // Receive cached login data if still valid
            let cachedLogin = try await api.asyncAuthenticate()

            // Only re-authenticate if no valid cache is available
            let newLogin: Bool
            if cachedLogin {
                newLogin = false
            } else {
                newLogin = try await api.asyncAuthenticate(restart: true)
            }

            if input.verbose {
                if cachedLogin {
                    print("Cached Login response:")
                } else if newLogin {
                    print("Received Login response:")
                } else {
                    print("Login failed.")
                }

                let response = api.apisession.loginResponseSnapshot
                print(prettyJSON(response))
            }

            return cachedLogin || newLogin
        } catch {
            print("Login test failed: \(error)")
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

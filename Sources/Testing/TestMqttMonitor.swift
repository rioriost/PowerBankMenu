//
//  TestMqttMonitor.swift
//  PowerBankMenu
//
//  MQTT monitor test harness for ticket 19
//

import Foundation

struct TestMqttMonitor {
    private static let triggerCooldownSeconds: TimeInterval = TimeInterval(
        SolixDefaults.triggerTimeoutDef)
    private static let statusCooldownSeconds: TimeInterval = TimeInterval(
        SolixDefaults.triggerTimeoutDef)
    @MainActor private static var lastRealtimeTriggerAt: Date?
    @MainActor private static var lastStatusRequestAt: Date?

    struct Input {
        let email: String
        let password: String
        let countryId: String
        let deviceSn: String?
        let realtimeTrigger: Bool
        let statusRequest: Bool
        let runtimeSeconds: Int
        let verbose: Bool

        init(
            email: String,
            password: String,
            countryId: String = "US",
            deviceSn: String? = nil,
            realtimeTrigger: Bool = true,
            statusRequest: Bool = false,
            runtimeSeconds: Int = 60,
            verbose: Bool = true
        ) {
            self.email = email
            self.password = password
            self.countryId = countryId
            self.deviceSn = deviceSn
            self.realtimeTrigger = realtimeTrigger
            self.statusRequest = statusRequest
            self.runtimeSeconds = runtimeSeconds
            self.verbose = verbose
        }
    }

    static func run(_ input: Input) async -> Bool {
        do {
            let env = ProcessInfo.processInfo.environment
            var config = ApiSessionConfiguration()
            if let timeoutValue = env["SOLIX_REQUEST_TIMEOUT"].flatMap({ Double($0) }) {
                let clamped = min(
                    Double(SolixDefaults.requestTimeoutMax),
                    max(Double(SolixDefaults.requestTimeoutMin), timeoutValue)
                )
                config.requestTimeout = clamped
            }
            let session = try ApiSession(
                email: input.email,
                password: input.password,
                countryId: input.countryId,
                configuration: config
            )
            let api = try SolixApi(apisession: session)

            if input.verbose {
                print("Testing Solix API: MQTT monitor")
            }

            _ = try await api.asyncAuthenticate()

            _ = try await ApiPoller.pollSites(api: api)
            _ = try await ApiPoller.pollDeviceDetails(api: api)

            guard let device = selectDevice(api: api, input: input) else {
                print("No device found for MQTT monitoring.")
                return false
            }

            guard let mqtt = await api.startMqttSession() as? MqttSession else {
                print("Failed to start MQTT session.")
                return false
            }
            if !mqtt.isConnected() {
                print("Failed to connect MQTT session.")
                api.stopMqttSession()
                return false
            }

            mqtt.message_callback { _, topic, message, data, model, deviceSn, valueUpdate in
                let deviceLabel = deviceSn ?? "unknown"
                let modelLabel = model ?? "unknown"
                let payload =
                    [
                        "topic": topic,
                        "device_sn": deviceLabel,
                        "model": modelLabel,
                        "value_update": valueUpdate,
                        "message": message,
                        "data": data ?? NSNull(),
                    ] as [String: Any]
                print(prettyJSON(payload))
            }

            subscribeRootTopics(mqtt: mqtt, device: device)

            if input.realtimeTrigger {
                _ = await sendRealtimeTrigger(mqtt: mqtt, device: device)
            }

            if input.statusRequest {
                _ = await sendStatusRequest(mqtt: mqtt, device: device)
            }

            if input.verbose {
                print("Monitoring MQTT messages for \(input.runtimeSeconds) seconds...")
            }

            let duration = max(1, input.runtimeSeconds)
            try await Task.sleep(nanoseconds: UInt64(duration) * 1_000_000_000)

            if input.verbose {
                print("Stopping MQTT session.")
            }
            api.stopMqttSession()
            return true
        } catch {
            print("MQTT monitor failed: \(error)")
            return false
        }
    }

    private static func selectDevice(api: SolixApi, input: Input) -> [String: Any]? {
        if let deviceSn = input.deviceSn {
            return api.devices[deviceSn]
        }
        return api.devices.values.first
    }

    private static func subscribeRootTopics(mqtt: MqttSession, device: [String: Any]) {
        let prefix = mqtt.getTopicPrefix(deviceDict: device, publish: false)
        if !prefix.isEmpty {
            mqtt.subscribe("\(prefix)#")
        }
        let cmdPrefix = mqtt.getTopicPrefix(deviceDict: device, publish: true)
        if !cmdPrefix.isEmpty {
            mqtt.subscribe("\(cmdPrefix)#")
        }
    }

    private static func sendRealtimeTrigger(mqtt: MqttSession, device: [String: Any]) async -> Bool {
        let now = Date()
        let shouldSend = await MainActor.run {
            if let last = lastRealtimeTriggerAt,
                now.timeIntervalSince(last) < triggerCooldownSeconds
            {
                return false
            }
            lastRealtimeTriggerAt = now
            return true
        }
        guard shouldSend else { return false }
        let cmd = generateMqttCommand(
            command: SolixMqttCommands.realtimeTrigger,
            parameters: ["trigger_timeout_sec": SolixDefaults.triggerTimeoutDef],
            model: device["device_pn"] as? String ?? device["product_code"] as? String
        )
        guard let cmd else { return false }
        mqtt.publish(deviceDict: device, hexBytes: cmd.hexbytes)
        return true
    }

    private static func sendStatusRequest(mqtt: MqttSession, device: [String: Any]) async -> Bool {
        let now = Date()
        let shouldSend = await MainActor.run {
            if let last = lastStatusRequestAt,
                now.timeIntervalSince(last) < statusCooldownSeconds
            {
                return false
            }
            lastStatusRequestAt = now
            return true
        }
        guard shouldSend else { return false }
        let cmd = generateMqttCommand(
            command: SolixMqttCommands.statusRequest,
            parameters: nil,
            model: device["device_pn"] as? String ?? device["product_code"] as? String
        )
        guard let cmd else { return false }
        mqtt.publish(deviceDict: device, hexBytes: cmd.hexbytes)
        return true
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

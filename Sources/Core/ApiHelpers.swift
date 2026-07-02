//
//  ApiHelpers.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/helpers.py
//

import CryptoKit
import Foundation

// MARK: - Request Counter

final class RequestCounter {
    private let lock = NSLock()
    private var elements: [(date: Date, info: String)] = []
    private(set) var throttled: Set<String> = []

    var description: String {
        "\(lastHourCount()) last hour, \(lastMinuteCount()) last minute"
    }

    func add(requestTime: Date? = nil, requestInfo: String = "") {
        lock.lock()
        elements.append((requestTime ?? Date(), requestInfo))
        lock.unlock()
        recycle()
    }

    func recycle(lastTime: Date? = nil) {
        let cutoff = lastTime ?? Date().addingTimeInterval(-3600)
        lock.lock()
        elements = elements.filter { $0.date > cutoff }
        lock.unlock()
    }

    func addThrottle(endpoint: String) {
        guard !endpoint.isEmpty else { return }
        lock.lock()
        throttled.insert(endpoint)
        lock.unlock()
    }

    func isThrottled(_ endpoint: String) -> Bool {
        lock.lock()
        let contains = throttled.contains(endpoint)
        lock.unlock()
        return contains
    }

    func lastMinuteCount() -> Int {
        let cutoff = Date().addingTimeInterval(-62)
        lock.lock()
        let count = elements.filter { $0.date > cutoff }.count
        lock.unlock()
        return count
    }

    func lastMinuteDetails() -> [(Date, String)] {
        let cutoff = Date().addingTimeInterval(-62)
        lock.lock()
        let details = elements.filter { $0.date > cutoff }.map { ($0.date, $0.info) }
        lock.unlock()
        return details
    }

    func lastHourCount() -> Int {
        let cutoff = Date().addingTimeInterval(-3600)
        lock.lock()
        let count = elements.filter { $0.date > cutoff }.count
        lock.unlock()
        return count
    }

    func lastHourDetails() -> [(Date, String)] {
        let cutoff = Date().addingTimeInterval(-3600)
        lock.lock()
        let details = elements.filter { $0.date > cutoff }.map { ($0.date, $0.info) }
        lock.unlock()
        return details
    }

    func getDetails(lastHour: Bool = false) -> String {
        let details = lastHour ? lastHourDetails() : lastMinuteDetails()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        var lines = details.map { "\(formatter.string(from: $0.0)) --> \($0.1)" }
        lines.append("Throttled Endpoints:")
        lock.lock()
        let throttledList = throttled.isEmpty ? ["None"] : Array(throttled)
        lock.unlock()
        lines.append(contentsOf: throttledList)
        return lines.joined(separator: "\n")
    }
}

// MARK: - Hashing

struct ApiHelpers {
    static func md5(_ data: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(data.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func md5(data: Data) -> String {
        let digest = Insecure.MD5.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Time

    static func getTimezoneGMTString() -> String {
        let seconds = TimeZone.current.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        return String(format: "GMT%+03d:%02d", hours, minutes)
    }

    static func generateTimestamp(inMilliseconds: Bool = false) -> String {
        let now = Date().timeIntervalSince1970
        let value = inMilliseconds ? Int(now * 1000) : Int(now)
        return String(value)
    }

    // MARK: - Conversions

    static func convertToKwh(_ value: Double, unit: String) -> Double? {
        let unitLower = unit.lowercased()
        switch unitLower {
        case "wh":
            return round(value / 1000 * 100) / 100
        case "mwh":
            return round(value * 1000 * 100) / 100
        case "gwh":
            return round(value * 1_000_000 * 100) / 100
        default:
            return value
        }
    }

    static func convertToKwh(_ value: String, unit: String) -> String? {
        guard let numeric = Double(value) else { return nil }
        guard let converted = convertToKwh(numeric, unit: unit) else { return nil }
        return String(converted)
    }

    // MARK: - Enum Helpers

    static func getEnumName<E: RawRepresentable>(
        _ enumType: E.Type,
        value: E.RawValue,
        default defaultValue: String? = nil
    ) -> String? {
        return E(rawValue: value).map { String(describing: $0) } ?? defaultValue
    }

    static func getEnumValue<E: RawRepresentable & CaseIterable>(
        _ enumType: E.Type,
        name: String,
        default defaultValue: E.RawValue? = nil
    ) -> E.RawValue? where E.AllCases.Element == E {
        return enumType.allCases.first { String(describing: $0) == name }?.rawValue ?? defaultValue
    }

    // MARK: - Rounding

    static func roundByFactor(_ value: Double, factor: Double) -> Double {
        let factorString = String(format: "%.15f", factor)
            .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        let decimals = max(0, factorString.split(separator: ".").dropFirst().first?.count ?? 0)
        let rounded = (value * pow(10, Double(decimals))).rounded() / pow(10, Double(decimals))
        return rounded == 0 ? 0 : rounded
    }
}

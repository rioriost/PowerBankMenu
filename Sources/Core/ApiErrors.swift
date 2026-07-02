//
//  ApiErrors.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/errors.py
//

import Foundation

// MARK: - Error Types

enum AnkerSolixError: Error, CustomStringConvertible {
    case authorization(message: String)
    case connect(message: String)
    case network(message: String)
    case server(message: String)
    case request(message: String)
    case itemNotFound(message: String)
    case itemExists(message: String)
    case itemLimitExceeded(message: String)
    case busy(message: String)
    case requestLimit(message: String)
    case verifyCode(message: String)
    case verifyCodeExpired(message: String)
    case needVerifyCode(message: String)
    case verifyCodeMax(message: String)
    case verifyCodeNoneMatch(message: String)
    case verifyCodePassword(message: String)
    case clientPublicKey(message: String)
    case tokenKickedOut(message: String)
    case invalidCredentials(message: String)
    case retryExceeded(message: String)
    case noAccessPermission(message: String)
    case unknown(message: String)

    var description: String {
        switch self {
        case .authorization(let message): return message
        case .connect(let message): return message
        case .network(let message): return message
        case .server(let message): return message
        case .request(let message): return message
        case .itemNotFound(let message): return message
        case .itemExists(let message): return message
        case .itemLimitExceeded(let message): return message
        case .busy(let message): return message
        case .requestLimit(let message): return message
        case .verifyCode(let message): return message
        case .verifyCodeExpired(let message): return message
        case .needVerifyCode(let message): return message
        case .verifyCodeMax(let message): return message
        case .verifyCodeNoneMatch(let message): return message
        case .verifyCodePassword(let message): return message
        case .clientPublicKey(let message): return message
        case .tokenKickedOut(let message): return message
        case .invalidCredentials(let message): return message
        case .retryExceeded(let message): return message
        case .noAccessPermission(let message): return message
        case .unknown(let message): return message
        }
    }
}

// MARK: - Error Mapping

struct ApiErrorMapper {
    static let map: [Int: @Sendable (String) -> AnkerSolixError] = [
        401: { .authorization(message: $0) },
        403: { .authorization(message: $0) },
        429: { .requestLimit(message: $0) },
        502: { .connect(message: $0) },
        504: { .connect(message: $0) },
        997: { .connect(message: $0) },
        998: { .network(message: $0) },
        999: { .server(message: $0) },
        10000: { .request(message: $0) },
        10003: { .request(message: $0) },
        10004: { .itemNotFound(message: $0) },
        10007: { .request(message: $0) },
        21105: { .busy(message: $0) },
        26050: { .verifyCode(message: $0) },
        26051: { .verifyCodeExpired(message: $0) },
        26052: { .needVerifyCode(message: $0) },
        26053: { .verifyCodeMax(message: $0) },
        26054: { .verifyCodeNoneMatch(message: $0) },
        26055: { .verifyCodePassword(message: $0) },
        26070: { .clientPublicKey(message: $0) },
        26084: { .tokenKickedOut(message: $0) },
        26108: { .invalidCredentials(message: $0) },
        26156: { .invalidCredentials(message: $0) },
        26161: { .request(message: $0) },
        31001: { .itemExists(message: $0) },
        31003: { .itemLimitExceeded(message: $0) },
        100053: { .retryExceeded(message: $0) },
        160003: { .noAccessPermission(message: $0) },
    ]

    static func makeError(from data: [String: Any], prefix: String = "API Error")
        -> AnkerSolixError?
    {
        guard let codeValue = data["code"] else { return nil }
        let code = Int("\(codeValue)") ?? 0
        let msg = (data["msg"] as? String) ?? "Error msg not found"
        let message = "(\(code)) \(prefix): \(msg)"

        if let builder = map[code] {
            return builder(message)
        }

        if code >= 10000 {
            return .unknown(message: message)
        }

        return nil
    }

    static func throwIfError(from data: [String: Any], prefix: String = "API Error") throws {
        if let error = makeError(from: data, prefix: prefix) {
            throw error
        }
    }
}

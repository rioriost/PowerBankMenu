//
//  ExportService.swift
//  PowerBankMenu
//
//  Minimal export service for writing cache JSON files.
//
import Foundation

final class ExportService {
    private let api: SolixApi
    private let fileManager = FileManager.default

    init(api: SolixApi) {
        self.api = api
    }

    struct ExportResult {
        let directory: URL
        let files: [URL]
    }

    func exportCaches(to directory: URL) throws -> ExportResult {
        try ensureDirectory(directory)

        var written: [URL] = []
        written.append(
            try writeJson(api.account, to: directory, filename: filename(for: "api_account")))
        written.append(
            try writeJson(api.sites, to: directory, filename: filename(for: "api_sites")))
        written.append(
            try writeJson(api.devices, to: directory, filename: filename(for: "api_devices")))

        return ExportResult(directory: directory, files: written)
    }

    // MARK: - Helpers

    private func ensureDirectory(_ url: URL) throws {
        if fileManager.fileExists(atPath: url.path) { return }
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func writeJson(_ object: Any, to directory: URL, filename: String) throws -> URL {
        let url = directory.appendingPathComponent(filename).appendingPathExtension("json")
        let data = try JSONSerialization.data(
            withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: [.atomic])
        return url
    }

    private func filename(for key: String) -> String {
        ApiFilePrefixes.map[key] ?? key
    }
}

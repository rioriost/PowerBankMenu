//
//  SolixApi.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/api.py (API entry class)
//

import Foundation

final class SolixApi: ApiBase {
    // Service placeholders (implemented in later tickets)
    var powerpanelApi: AnyObject?
    var hesApi: AnyObject?
    var energyService: EnergyService?
    var scheduleService: ScheduleService?
    var vehicleService: VehicleService?
    var powerPanelService: PowerPanelService?
    var exportService: ExportService?
    var hesService: HesService?

    // MARK: - Initialization

    override init(
        email: String? = nil,
        password: String? = nil,
        countryId: String? = nil,
        apisession: ApiSession? = nil
    ) throws {
        try super.init(
            email: email,
            password: password,
            countryId: countryId,
            apisession: apisession
        )
        self.energyService = EnergyService(api: self)
        self.scheduleService = ScheduleService(api: self)
        self.vehicleService = VehicleService(api: self)
        self.powerPanelService = PowerPanelService(api: self)
        self.hesService = HesService(api: self)
        self.exportService = ExportService(api: self)
    }

    // MARK: - Delegations

    var requestCount: RequestCounter {
        apisession.requestCount
    }

    @discardableResult
    func asyncAuthenticate(restart: Bool = false) async throws -> Bool {
        try await apisession.authenticate(restart: restart)
    }

    func request(
        method: String,
        endpoint: String,
        headers: [String: String] = [:],
        json: [String: Any] = [:]
    ) async throws -> [String: Any] {
        try await apisession.request(
            method: method,
            endpoint: endpoint,
            headers: headers,
            json: json
        )
    }
}

//
//  VehicleService.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/vehicle.py (core vehicle endpoints)
//

import Foundation

final class VehicleService {
    private let api: SolixApi

    init(api: SolixApi) {
        self.api = api
    }

    // MARK: - Vehicle List / Details

    func getVehicleList() async throws -> [String: Any] {
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_user_vehicles"] ?? "",
            json: [:]
        )

        let data = (response["data"] as? [String: Any]) ?? [:]
        let list = data["vehicle_list"] as? [[String: Any]] ?? []

        var vehicles: [String: Any] = [:]
        let oldVehicles = api.account["vehicles"] as? [String: Any] ?? [:]

        for vehicle in list {
            if let vehicleId = vehicle["vehicle_id"] as? String {
                var merged = (oldVehicles[vehicleId] as? [String: Any]) ?? [:]
                merged["type"] = SolixDeviceType.vehicle.rawValue
                for (k, v) in vehicle { merged[k] = v }
                vehicles[vehicleId] = merged
            }
        }

        api._update_account(details: ["vehicles": vehicles])
        api.account["vehicles_registered"] = Array(vehicles.keys)

        return data
    }

    func getVehicleDetails(vehicleId: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["vehicle_id": vehicleId]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_user_vehicle_details"] ?? "",
            json: payload
        )

        let data = (response["data"] as? [String: Any]) ?? [:]
        if let id = data["vehicle_id"] as? String {
            var vehicles = api.account["vehicles"] as? [String: Any] ?? [:]
            var vehicle = (vehicles[id] as? [String: Any]) ?? [:]
            vehicle["type"] = SolixDeviceType.vehicle.rawValue
            for (k, v) in data { vehicle[k] = v }
            vehicles[id] = vehicle
            api._update_account(details: ["vehicles": vehicles])
        }

        return data
    }

    // MARK: - Brand / Model Options

    func getBrandList() async throws -> [String: Any] {
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_vehicle_brands"] ?? "",
            json: [:]
        )
        let data = (response["data"] as? [String: Any]) ?? [:]

        let brandRoot = api.account["vehicle_brands"] as? [String: Any] ?? [:]
        let list = data["brand_list"] as? [String] ?? []
        var newRoot: [String: Any] = [:]
        for brand in list {
            newRoot[brand] = brandRoot[brand] ?? [:]
        }
        newRoot["cached"] = true
        api._update_account(details: ["vehicle_brands": newRoot])

        return data
    }

    func getBrandModels(brand: String) async throws -> [String: Any] {
        let payload: [String: Any] = ["brand_name": brand]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_vehicle_brand_models"] ?? "",
            json: payload
        )
        let data = (response["data"] as? [String: Any]) ?? [:]

        let models = data["model_list"] as? [String] ?? []
        var brandRoot = api.account["vehicle_brands"] as? [String: Any] ?? [:]
        var modelMap: [String: Any] = [:]
        for model in models {
            modelMap[model] = (brandRoot[brand] as? [String: Any])?[model] ?? [:]
        }
        modelMap["cached"] = true
        brandRoot[brand] = modelMap
        api._update_account(details: ["vehicle_brands": brandRoot])

        return data
    }

    func getModelYears(brand: String, model: String) async throws -> [String: Any] {
        let payload: [String: Any] = [
            "brand_name": brand,
            "model_name": model,
        ]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_vehicle_model_years"] ?? "",
            json: payload
        )
        let data = (response["data"] as? [String: Any]) ?? [:]

        let years = data["year_list"] as? [Int] ?? []
        var brandRoot = api.account["vehicle_brands"] as? [String: Any] ?? [:]
        var modelMap = brandRoot[brand] as? [String: Any] ?? [:]
        let yearMap = modelMap[model] as? [String: Any] ?? [:]

        var newYearMap: [String: Any] = [:]
        for year in years {
            let key = String(year)
            newYearMap[key] = yearMap[key] ?? [:]
        }
        newYearMap["cached"] = true

        modelMap[model] = newYearMap
        brandRoot[brand] = modelMap
        api._update_account(details: ["vehicle_brands": brandRoot])

        return data
    }

    func getModelYearAttributes(brand: String, model: String, year: Int) async throws -> [String:
        Any]
    {
        let payload: [String: Any] = [
            "brand_name": brand,
            "model_name": model,
            "productive_year": year,
        ]
        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["get_vehicle_year_attributes"] ?? "",
            json: payload
        )
        let data = (response["data"] as? [String: Any]) ?? [:]

        let list = data["car_model_list"] as? [[String: Any]] ?? []
        var brandRoot = api.account["vehicle_brands"] as? [String: Any] ?? [:]
        var modelMap = brandRoot[brand] as? [String: Any] ?? [:]
        var yearMap = modelMap[model] as? [String: Any] ?? [:]
        let idMap = yearMap[String(year)] as? [String: Any] ?? [:]

        var newIdMap: [String: Any] = [:]
        for item in list {
            let id = String(describing: item["id"] ?? "")
            var existing = idMap[id] as? [String: Any] ?? [:]
            for (k, v) in item { existing[k] = v }
            newIdMap[id] = existing
        }
        newIdMap["cached"] = true
        yearMap[String(year)] = newIdMap
        modelMap[model] = yearMap
        brandRoot[brand] = modelMap
        api._update_account(details: ["vehicle_brands": brandRoot])

        return data
    }

    // MARK: - Cached Options Helpers

    func updateVehicleOptions(vehicle: SolixVehicle, cacheChain: Bool = true) async throws
        -> [String]
    {
        if cacheChain || vehicle.brand.isEmpty {
            let brands = api.account["vehicle_brands"] as? [String: Any] ?? [:]
            if brands["cached"] == nil {
                _ = try await getBrandList()
            }
        }

        if !vehicle.brand.isEmpty {
            let brands = api.account["vehicle_brands"] as? [String: Any] ?? [:]
            let brandMap = brands[vehicle.brand] as? [String: Any] ?? [:]
            if cacheChain || vehicle.model.isEmpty, brandMap["cached"] == nil {
                _ = try await getBrandModels(brand: vehicle.brand)
            }
        }

        if !vehicle.brand.isEmpty, !vehicle.model.isEmpty {
            let brands = api.account["vehicle_brands"] as? [String: Any] ?? [:]
            let brandMap = brands[vehicle.brand] as? [String: Any] ?? [:]
            let modelMap = brandMap[vehicle.model] as? [String: Any] ?? [:]
            if cacheChain || vehicle.productiveYear == 0, modelMap["cached"] == nil {
                _ = try await getModelYears(brand: vehicle.brand, model: vehicle.model)
            }
        }

        if !vehicle.brand.isEmpty, !vehicle.model.isEmpty, vehicle.productiveYear > 0 {
            let brands = api.account["vehicle_brands"] as? [String: Any] ?? [:]
            let brandMap = brands[vehicle.brand] as? [String: Any] ?? [:]
            let modelMap = brandMap[vehicle.model] as? [String: Any] ?? [:]
            let yearMap = modelMap[String(vehicle.productiveYear)] as? [String: Any] ?? [:]
            if yearMap["cached"] == nil {
                _ = try await getModelYearAttributes(
                    brand: vehicle.brand,
                    model: vehicle.model,
                    year: vehicle.productiveYear
                )
            }
        }

        return getVehicleOptions(vehicle: vehicle)
    }

    func getVehicleOptions(vehicle: SolixVehicle, extendAttributes: Bool = false) -> [String] {
        guard !vehicle.brand.isEmpty || vehicle.model.isEmpty else { return [] }

        let brands = api.account["vehicle_brands"] as? [String: Any] ?? [:]
        if vehicle.brand.isEmpty {
            return brands.keys.filter { $0 != "cached" }.sorted()
        }

        let brandMap = brands[vehicle.brand] as? [String: Any] ?? [:]
        if vehicle.model.isEmpty {
            return brandMap.keys.filter { $0 != "cached" }.sorted()
        }

        let modelMap = brandMap[vehicle.model] as? [String: Any] ?? [:]
        if vehicle.productiveYear == 0 {
            return modelMap.keys.filter { $0 != "cached" }.sorted()
        }

        let yearMap = modelMap[String(vehicle.productiveYear)] as? [String: Any] ?? [:]
        let keys = yearMap.keys.filter { $0 != "cached" }
        if extendAttributes {
            return keys.compactMap { key in
                guard let item = yearMap[key] as? [String: Any] else { return nil }
                return SolixVehicle(vehicle: item).idAttributes()
            }
        }
        return keys.sorted()
    }

    func getVehicleAttributes(vehicle: SolixVehicle) async throws -> SolixVehicle? {
        guard !vehicle.brand.isEmpty, !vehicle.model.isEmpty, vehicle.productiveYear > 0 else {
            return nil
        }

        let options = try await updateVehicleOptions(vehicle: vehicle)
        let brands = api.account["vehicle_brands"] as? [String: Any] ?? [:]
        let brandMap = brands[vehicle.brand] as? [String: Any] ?? [:]
        let modelMap = brandMap[vehicle.model] as? [String: Any] ?? [:]
        let yearMap = modelMap[String(vehicle.productiveYear)] as? [String: Any] ?? [:]

        for opt in options {
            if let item = yearMap[opt] as? [String: Any] {
                let candidate = SolixVehicle(vehicle: item)
                if vehicle.modelId == nil || candidate.modelId == vehicle.modelId {
                    return candidate
                }
            }
        }

        return nil
    }

    // MARK: - Create / Manage Vehicle

    func createVehicle(name: String, vehicle: SolixVehicle) async throws -> [String: Any] {
        guard !name.isEmpty else {
            throw AnkerSolixError.request(message: "Vehicle name is required.")
        }

        let payload: [String: Any] = [
            "user_vehicle_info": [
                ["vehicle_name": name].merging(vehicle.asDictionary(skipEmpty: true)) { _, new in
                    new
                }
            ]
        ]

        let response = try await api.request(
            method: "POST",
            endpoint: ApiEndpoints.powerService["vehicle_add"] ?? "",
            json: payload
        )
        try ApiErrorMapper.throwIfError(from: response)

        _ = try await getVehicleList()
        if let list = (api.account["vehicles"] as? [String: Any])?.values {
            for case let vehicleData as [String: Any] in list {
                if (vehicleData["vehicle_name"] as? String) == name,
                    let id = vehicleData["vehicle_id"] as? String
                {
                    return try await getVehicleDetails(vehicleId: id)
                }
            }
        }

        return [:]
    }

    func manageVehicle(
        vehicleId: String,
        action: String,
        vehicle: SolixVehicle? = nil,
        chargeOrder: [String: Any]? = nil
    ) async throws -> [String: Any] {
        let actionLower = action.lowercased()
        let validActions = ["setdefault", "setcharge", "update", "restore", "delete"]
        guard validActions.contains(actionLower) else {
            throw AnkerSolixError.request(message: "Unsupported vehicle action: \(action)")
        }

        var payload: [String: Any] = ["vehicle_id": vehicleId]

        switch actionLower {
        case "delete":
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["vehicle_delete"] ?? "",
                json: payload
            )
            try ApiErrorMapper.throwIfError(from: response)
            _ = try await getVehicleList()
            return [:]

        case "setdefault":
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["vehicle_set_default"] ?? "",
                json: payload
            )
            try ApiErrorMapper.throwIfError(from: response)

        case "setcharge":
            guard let chargeOrder else {
                throw AnkerSolixError.request(message: "chargeOrder is required for setcharge.")
            }
            for (k, v) in chargeOrder { payload[k] = v }
            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["vehicle_set_charging"] ?? "",
                json: payload
            )
            try ApiErrorMapper.throwIfError(from: response)

        case "update", "restore":
            guard let vehicle else {
                throw AnkerSolixError.request(
                    message: "Vehicle attributes required for update/restore.")
            }
            let data = vehicle.asDictionary(skipEmpty: true)
            for (k, v) in data { payload[k] = v }

            let response = try await api.request(
                method: "POST",
                endpoint: ApiEndpoints.powerService["vehicle_update"] ?? "",
                json: payload
            )
            try ApiErrorMapper.throwIfError(from: response)

        default:
            break
        }

        _ = try await getVehicleList()
        return try await getVehicleDetails(vehicleId: vehicleId)
    }
}

//
//  ApiTypes.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/apitypes.py
//

import Foundation

// MARK: - API Servers & Headers

struct ApiServers {
    static let map: [String: String] = [
        "eu": "https://ankerpower-api-eu.anker.com",
        "com": "https://ankerpower-api.anker.com",
    ]
}

struct ApiLogin {
    static let path = "passport/login"
}

struct ApiKeyExchange {
    static let path = "openapi/oauth/key/exchange"
}

struct ApiHeaders {
    static let base: [String: String] = [
        "content-type": "application/json",
        "model-type": "DESKTOP",
        "app-name": "anker_power",
        "os-type": "android",
    ]
}

struct ApiCountries {
    static let map: [String: [String]] = [
        "com": [
            "DZ", "LB", "SY", "EG", "LY", "TN", "MA", "JO", "PS", "AR", "AU", "BR", "HK", "IN",
            "JP", "MX", "NG", "NZ", "RU", "SG", "ZA", "KR", "TW", "US", "CA", "RO",
        ],
        "eu": [
            "DE", "BE", "EL", "LT", "PT", "BG", "ES", "LU", "CZ", "FR", "HU", "SI", "DK", "HR",
            "MT", "SK", "IT", "NL", "FI", "EE", "CY", "AT", "SE", "IE", "LV", "PL", "UK", "IS",
            "NO", "LI", "CH", "BA", "ME", "MD", "MK", "GE", "AL", "RS", "TR", "UA", "XK", "AM",
            "BY", "AZ", "IL",
        ],
    ]
}

// MARK: - API Endpoints

struct ApiEndpoints {
    static let powerService: [String: String] = [
        "homepage": "power_service/v1/site/get_site_homepage",
        "site_list": "power_service/v1/site/get_site_list",
        "site_detail": "power_service/v1/site/get_site_detail",
        "site_rules": "power_service/v1/site/get_site_rules",
        "scene_info": "power_service/v1/site/get_scen_info",
        "user_devices": "power_service/v1/site/list_user_devices",
        "charging_devices": "power_service/v1/site/get_charging_device",
        "get_device_parm": "power_service/v1/site/get_site_device_param",
        "set_device_parm": "power_service/v1/site/set_site_device_param",
        "energy_analysis": "power_service/v1/site/energy_analysis",
        "home_load_chart": "power_service/v1/site/get_home_load_chart",
        "wifi_list": "power_service/v1/site/get_wifi_info_list",
        "get_site_price": "power_service/v1/site/get_site_price",
        "update_site_price": "power_service/v1/site/update_site_price",
        "get_forecast_schedule": "power_service/v1/site/get_schedule",
        "get_co2_ranking": "power_service/v1/site/co2_ranking",
        "get_site_power_limit": "power_service/v1/site/get_power_limit",
        "get_auto_upgrade": "power_service/v1/app/get_auto_upgrade",
        "set_auto_upgrade": "power_service/v1/app/set_auto_upgrade",
        "bind_devices": "power_service/v1/app/get_relate_and_bind_devices",
        "get_device_load": "power_service/v1/app/device/get_device_home_load",
        "set_device_load": "power_service/v1/app/device/set_device_home_load",
        "get_ota_info": "power_service/v1/app/compatible/get_ota_info",
        "get_ota_update": "power_service/v1/app/compatible/get_ota_update",
        "solar_info": "power_service/v1/app/compatible/get_compatible_solar_info",
        "get_cutoff": "power_service/v1/app/compatible/get_power_cutoff",
        "set_cutoff": "power_service/v1/app/compatible/set_power_cutoff",
        "compatible_process": "power_service/v1/app/compatible/get_compatible_process",
        "get_device_fittings": "power_service/v1/app/get_relate_device_fittings",
        "get_upgrade_record": "power_service/v1/app/get_upgrade_record",
        "check_upgrade_record": "power_service/v1/app/check_upgrade_record",
        "get_device_attributes": "power_service/v1/app/device/get_device_attrs",
        "set_device_attributes": "power_service/v1/app/device/set_device_attrs",
        "get_config": "power_service/v1/app/get_config",
        "get_installation": "power_service/v1/app/compatible/get_installation",
        "set_installation": "power_service/v1/app/compatible/set_installation",
        "get_third_platforms": "power_service/v1/app/third/platform/list",
        "get_token_by_userid": "power_service/v1/app/get_token_by_userid",
        "get_shelly_status": "power_service/v1/app/get_user_op_shelly_status",
        "get_device_income": "power_service/v1/app/device/get_device_income",
        "get_device_group": "power_service/v1/app/group/get_group_devices",
        "get_device_charge_order_stats": "power_service/v1/app/order/get_charge_order_stats",
        "get_device_charge_order_stats_list":
            "power_service/v1/app/order/get_charge_order_stats_list",
        "get_ocpp_endpoint_list": "power_service/v1/app/get_ocpp_endpoint_list",
        "get_device_ocpp_info": "power_service/v1/app/get_ocpp_info",
        "get_vehicle_brands": "power_service/v1/app/get_brand_list",
        "get_vehicle_brand_models": "power_service/v1/app/get_models",
        "get_vehicle_model_years": "power_service/v1/app/get_model_years",
        "get_vehicle_year_attributes": "power_service/v1/app/get_model_list",
        "get_user_vehicles": "power_service/v1/app/vehicle/get_vehicle_list",
        "get_user_vehicle_details": "power_service/v1/app/vehicle/get_vehicle_detail",
        "vehicle_add": "power_service/v1/app/vehicle/add_vehicle",
        "vehicle_update": "power_service/v1/app/vehicle/update_vehicle",
        "vehicle_delete": "power_service/v1/app/vehicle/delete_vehicle",
        "vehicle_set_charging": "power_service/v1/app/vehicle/set_charging_vehicle",
        "vehicle_set_default": "power_service/v1/app/vehicle/set_default",
        "get_tamper_records": "power_service/v1/device/get_tamper_records",
        "get_currency_list": "power_service/v1/currency/get_list",
        "get_dynamic_price_sites": "power_service/v1/dynamic_price/check_available",
        "get_dynamic_price_providers": "power_service/v1/dynamic_price/support_option",
        "get_dynamic_price_details": "power_service/v1/dynamic_price/price_detail",
        "get_message_unread": "power_service/v1/get_message_unread",
        "get_message": "power_service/v1/get_message",
        "get_product_categories": "power_service/v1/product_categories",
        "get_product_accessories": "power_service/v1/product_accessories",
        "get_ai_ems_status": "power_service/v1/ai_ems/get_status",
        "get_ai_ems_profit": "power_service/v1/ai_ems/profit",
        "get_ota_batch": "app/ota/batch/check_update",
        "get_mqtt_info": "app/devicemanage/get_user_mqtt_info",
        "get_shared_device": "app/devicerelation/get_shared_device",
        "get_device_pv_status": "charging_pv_svc/getPvStatus",
        "get_device_pv_total_statistics": "charging_pv_svc/getPvTotalStatistics",
        "get_device_pv_statistics": "charging_pv_svc/statisticsPv",
        "get_device_pv_price": "charging_pv_svc/selectUserTieredElecPrice",
        "set_device_pv_price": "charging_pv_svc/updateUserTieredElecPrice",
        "set_device_pv_power": "charging_pv_svc/set_aps_power",
        "get_device_rfid_cards": "power_service/v1/rfid/get_device_cards",
        "charger_get_charging_modes": "mini_power/v1/app/charging/get_charging_mode_list",
        "charger_get_triggers": "mini_power/v1/app/egg/get_easter_egg_trigger_list",
        "charger_get_statistics": "mini_power/v1/app/power/get_day_power_data",
        "charger_get_device_setting": "mini_power/v1/app/setting/get_device_setting",
        "charger_get_screensavers": "mini_power/v1/app/style/get_clock_screensavers",
    ]

    static let chargingService: [String: String] = [
        "get_error_info": "charging_energy_service/get_error_infos",
        "get_system_running_info": "charging_energy_service/get_system_running_info",
        "energy_statistics": "charging_energy_service/energy_statistics",
        "get_rom_versions": "charging_energy_service/get_rom_versions",
        "get_device_info": "charging_energy_service/get_device_infos",
        "get_wifi_info": "charging_energy_service/get_wifi_info",
        "get_installation_inspection": "charging_energy_service/get_installation_inspection",
        "get_utility_rate_plan": "charging_energy_service/get_utility_rate_plan",
        "report_device_data": "charging_energy_service/report_device_data",
        "get_configs": "charging_energy_service/get_configs",
        "get_sns": "charging_energy_service/get_sns",
        "get_monetary_units": "charging_energy_service/get_world_monetary_unit",
    ]

    static let hesService: [String: String] = [
        "get_product_info": "charging_hes_svc/get_device_product_info",
        "get_heat_pump_plan": "charging_hes_svc/get_heat_pump_plan_json",
        "get_electric_plan_list": "charging_hes_svc/get_electric_utility_and_electric_plan_list",
        "get_system_running_info": "charging_hes_svc/get_system_running_info",
        "get_system_profit": "charging_hes_svc/get_system_profit_detail",
        "energy_statistics": "charging_hes_svc/get_energy_statistics",
        "get_monetary_units": "charging_hes_svc/get_world_monetary_unit",
        "get_install_info": "charging_hes_svc/get_install_info",
        "get_wifi_info": "charging_hes_svc/get_wifi_info",
        "get_installer_info": "charging_hes_svc/get_installer_info",
        "get_system_running_time": "charging_hes_svc/get_system_running_time",
        "get_mi_layout": "charging_hes_svc/get_mi_layout",
        "get_conn_net_tips": "charging_hes_svc/get_conn_net_tips",
        "get_hes_dev_info": "charging_hes_svc/get_hes_dev_info",
        "report_device_data": "charging_hes_svc/report_device_data",
        "get_evcharger_standalone": "charging_hes_svc/get_user_bind_and_not_in_station_evchargers",
        "get_evcharger_station_info": "charging_hes_svc/get_evcharger_station_info",
    ]
}

// MARK: - API File Prefixes

struct ApiFilePrefixes {
    static let map: [String: String] = [
        "mqtt_message": "mqtt_msg",
        "homepage": "homepage",
        "site_list": "site_list",
        "bind_devices": "bind_devices",
        "user_devices": "user_devices",
        "charging_devices": "charging_devices",
        "get_auto_upgrade": "auto_upgrade",
        "get_config": "config",
        "site_rules": "list_site_rules",
        "get_installation": "installation",
        "get_site_price": "price",
        "get_site_power_limit": "power_limit",
        "get_device_parm": "device_parm",
        "get_product_categories": "list_products",
        "get_product_accessories": "list_accessories",
        "get_third_platforms": "list_third_platforms",
        "get_token_by_userid": "get_token",
        "get_shelly_status": "shelly_status",
        "scene_info": "scene",
        "site_detail": "site_detail",
        "wifi_list": "wifi_list",
        "energy_solarbank": "energy_solarbank",
        "energy_solar_production": "energy_solar_production",
        "energy_home_usage": "energy_home_usage",
        "energy_grid": "energy_grid",
        "solar_info": "solar_info",
        "compatible_process": "compatible_process",
        "get_cutoff": "power_cutoff",
        "get_device_fittings": "device_fittings",
        "get_device_load": "device_load",
        "get_ota_batch": "ota_batch",
        "get_ota_update": "ota_update",
        "get_ota_info": "ota_info",
        "get_upgrade_record": "upgrade_record",
        "check_upgrade_record": "check_upgrade_record",
        "get_shared_device": "shared_device",
        "get_device_attributes": "device_attrs",
        "get_message_unread": "message_unread",
        "get_currency_list": "currency_list",
        "get_co2_ranking": "co2_ranking",
        "get_forecast_schedule": "forecast_schedule",
        "get_dynamic_price_sites": "dynamic_price_sites",
        "get_dynamic_price_providers": "dynamic_price_providers",
        "get_dynamic_price_details": "dynamic_price_details",
        "get_device_income": "device_income",
        "get_ai_ems_status": "ai_ems_status",
        "get_ai_ems_profit": "ai_ems_profit",
        "get_tamper_records": "tamper_records",
        "get_device_rfid_cards": "rfid_cards",
        "get_device_group": "device_group",
        "get_device_charge_order_stats": "charge_order_stats",
        "get_device_charge_order_stats_list": "charge_order_stats_list",
        "get_ocpp_endpoint_list": "ocpp_endpoint_list",
        "get_device_ocpp_info": "ocpp_info",
        "get_vehicle_brands": "vehicle_brands",
        "get_vehicle_brand_models": "vehicle_brand_models",
        "get_vehicle_model_years": "vehicle_model_years",
        "get_vehicle_year_attributes": "vehicle_year_attributes",
        "get_user_vehicles": "user_vehicles",
        "get_user_vehicle_details": "user_vehicle_details",
        "api_account": "api_account",
        "api_sites": "api_sites",
        "api_devices": "api_devices",
        "get_device_pv_status": "device_pv_status",
        "get_device_pv_total_statistics": "device_pv_total_statistics",
        "get_device_pv_statistics": "device_pv_statistics",
        "get_device_pv_price": "device_pv_price",
        "charger_get_charging_modes": "charger_charging_modes",
        "charger_get_triggers": "charger_triggers",
        "charger_get_statistics": "charger_statistics",
        "charger_get_device_setting": "charger_device_setting",
        "charger_get_screensavers": "charger_screensavers",
        "charging_get_error_info": "charging_error_info",
        "charging_get_system_running_info": "charging_system_running_info",
        "charging_energy_solar": "charging_energy_solar",
        "charging_energy_hes": "charging_energy_hes",
        "charging_energy_pps": "charging_energy_pps",
        "charging_energy_home": "charging_energy_home",
        "charging_energy_grid": "charging_energy_grid",
        "charging_energy_diesel": "charging_energy_diesel",
        "charging_energy_solar_today": "charging_energy_solar_today",
        "charging_energy_hes_today": "charging_energy_hes_today",
        "charging_energy_pps_today": "charging_energy_pps_today",
        "charging_energy_home_today": "charging_energy_home_today",
        "charging_energy_grid_today": "charging_energy_grid_today",
        "charging_energy_diesel_today": "charging_energy_diesel_today",
        "charging_get_rom_versions": "charging_rom_versions",
        "charging_get_device_info": "charging_device_info",
        "charging_get_wifi_info": "charging_wifi_info",
        "charging_get_installation_inspection": "charging_installation_inspection",
        "charging_get_utility_rate_plan": "charging_utility_rate_plan",
        "charging_report_device_data": "charging_report_device_data",
        "charging_get_configs": "charging_configs",
        "charging_get_sns": "charging_sns",
        "charging_get_monetary_units": "charging_monetary_units",
        "hes_get_product_info": "hes_product_info",
        "hes_get_heat_pump_plan": "hes_heat_pump_plan",
        "hes_get_electric_plan_list": "hes_electric_plan",
        "hes_get_system_running_info": "hes_system_running_info",
        "hes_energy_solar": "hes_energy_solar",
        "hes_energy_hes": "hes_energy_hes",
        "hes_energy_pps": "hes_energy_pps",
        "hes_energy_home": "hes_energy_home",
        "hes_energy_grid": "hes_energy_grid",
        "hes_energy_solar_today": "hes_energy_solar_today",
        "hes_energy_hes_today": "hes_energy_hes_today",
        "hes_energy_pps_today": "hes_energy_pps_today",
        "hes_energy_home_today": "hes_energy_home_today",
        "hes_energy_grid_today": "hes_energy_grid_today",
        "hes_get_monetary_units": "hes_monetary_units",
        "hes_get_install_info": "hes_install_info",
        "hes_get_wifi_info": "hes_wifi_info",
        "hes_get_installer_info": "hes_installer_info",
        "hes_get_system_profit": "hes_system_profit",
        "hes_get_system_running_time": "hes_system_running_time",
        "hes_get_mi_layout": "hes_mi_layout",
        "hes_get_conn_net_tips": "hes_conn_net_tips",
        "hes_get_hes_dev_info": "hes_dev_info",
        "hes_report_device_data": "hes_report_device_data",
        "hes_get_evcharger_standalone": "hes_evcharger_standalone",
        "hes_get_evcharger_station_info": "hes_evcharger_station_info",
    ]
}

// MARK: - Login Response Schema (Keys)

struct LoginResponseSchema {
    static let keys: [String] = [
        "user_id", "email", "nick_name", "auth_token", "token_expires_at", "avatar", "mac_addr",
        "domain", "ab_code", "token_id", "geo_key", "privilege", "phone_code", "phone",
        "phone_number", "phone_code_2fa", "phone_2fa", "server_secret_info", "params", "trust_list",
        "fa_info", "country_code", "ap_cloud_user_id",
    ]
}

// MARK: - Enums

enum SolixDeviceType: String {
    case account
    case system
    case virtual
    case solarbank
    case combinerBox = "combiner_box"
    case inverter
    case smartmeter
    case smartplug
    case pps
    case powerpanel
    case powercooler
    case hes
    case solarbankPps = "solarbank_pps"
    case charger
    case powerbank
    case evCharger = "ev_charger"
    case vehicle
}

enum SolixParmType: String {
    case solarbankSchedule = "4"
    case solarbank2Schedule = "6"
    case solarbankScheduleEnforced = "9"
    case solarbankTariffSchedule = "12"
    case solarbankAuthorizations = "13"
    case solarbankPowerdock = "16"
    case solarbankStation = "18"
    case solarbankThirdPartyPv = "26"
}

enum SolarbankPowerMode: Int {
    case unknown = 0
    case normal = 1
    case advanced = 2
}

enum SolarbankDischargePriorityMode: Int {
    case unknown = -1
    case off = 0
    case on = 1
}

enum SolarbankAiemsStatus: Int {
    case unknown = 0
    case untrained = 3
    case learning = 4
    case trained = 5
}

enum SolarbankAiemsRuntimeStatus: Int {
    case unknown = -1
    case inactive = 0
    case running = 1
    case failure = 2
}

enum SolixTariffTypes: Int {
    case unknown = 0
    case peak = 1
    case midPeak = 2
    case offPeak = 3
    case valley = 4
}

enum SolixPriceTypes: String {
    case unknown
    case fixed
    case useTime = "use_time"
    case dynamic
}

enum SolixDayTypes: String {
    case weekday
    case weekend
    case all
}

enum SolarbankUsageMode: Int {
    case unknown = 0
    case smartmeter = 1
    case smartplugs = 2
    case manual = 3
    case backup = 4
    case useTime = 5
    case smart = 7
    case timeSlot = 8
}

enum SolixDeviceStatus: String {
    case offline = "0"
    case online = "1"
    case unknown
}

enum SolarbankStatus: String {
    case detection = "0"
    case protectionCharge = "03"
    case bypass = "1"
    case bypassDischarge = "12"
    case discharge = "2"
    case charge = "3"
    case chargeBypass = "31"
    case chargeAc = "32"
    case chargePriority = "37"
    case wakeup = "4"
    case coldWakeup = "116"
    case fullyCharged = "5"
    case fullBypass = "6"
    case standby = "7"
    case unknown
}

enum SolarbankLightMode: String {
    case normal = "0"
    case mood = "1"
    case unknown
}

enum SolarbankParallelTypes: String {
    case single
    case cascaded
    case ae100
    case ae100v2
    case diy
}

enum SmartmeterStatus: String {
    case ok = "0"
    case unknown
}

enum PowerdockStatus: String {
    case ok = "0"
    case unknown
}

enum SolarbankGridStatus: String {
    case connected = "1"
    case connecting = "3"
    case disconnected = "6"
    case unknown
}

enum SolixGridStatus: String {
    case ok = "0"
    case unknown
}

enum SolixPlantStatus: String {
    case onGrid = "1"
    case offGrid = "2"
    case standby = "3"
    case fault = "4"
    case unknown
}

enum SolixBatteryStatus: String {
    case standby = "0"
    case charging = "1"
    case discharging = "2"
    case sleep = "3"
    case unknown
}

enum SolixRoleStatus: String {
    case primary = "1"
    case subordinate = "2"
    case unknown
}

enum SolixNetworkStatus: String {
    case wifi = "1"
    case lan = "2"
    case mobile = "3"
    case unknown
}

enum SolixSwitchMode: Int {
    case off = 0
    case on = 1
    case unknown = -1
}

enum SolixSwitchModeV2: String {
    case on = "1"
    case off = "2"
    case unknown
}

enum SolixPpsOutputStatus: String {
    case smart = "0"
    case normal = "1"
    case unknown
}

enum SolixPpsOutputMode: String {
    case normal = "1"
    case smart = "2"
    case unknown
}

enum SolixPpsOutputModeV2: String {
    case normal = "0"
    case smart = "1"
    case unknown
}

enum SolixPpsChargingStatus: String {
    case inactive = "0"
    case solar = "1"
    case inputPower = "2"
    case both = "3"
    case unknown
}

enum SolixPpsPortStatus: String {
    case inactive = "0"
    case discharging = "1"
    case charging = "2"
    case unknown
}

enum SolixPpsDisplayMode: String {
    case off = "0"
    case low = "1"
    case medium = "2"
    case high = "3"
    case blinking = "4"
    case unknown
}

enum SolixChargerPortStatus: String {
    case inactive = "0"
    case active = "1"
    case unknown
}

enum SolixPhaseMode: String {
    case onePhase = "1"
    case threePhase = "3"
    case unknown
}

enum SolixOcppConnectionStatus: String {
    case disconnected = "0"
    case connecting = "1"
    case connected = "2"
    case unknown
}

enum SolixCpSignalStatus: String {
    case a12v = "0"
    case b1_9v = "3"
    case b2_9v = "4"
    case c1_6v = "5"
    case c2_6v = "6"
    case error = "7"
    case d1_3v = "8"
    case d2_3v = "9"
    case e0v = "10"
    case fMinus12v = "11"
    case unknown
}

enum SolixEvChargerStatus: String {
    case standby = "0"
    case preparing = "1"
    case charging = "2"
    case chargerPaused = "3"
    case vehiclePaused = "4"
    case completed = "5"
    case reserving = "6"
    case disabled = "7"
    case error = "8"
    case unknown
}

enum SolixEvChargerWipeMode: String {
    case off = "0"
    case startCharge = "1"
    case stopCharge = "2"
    case boostCharge = "3"
    case unknown
}

enum SolixSmartTouchMode: String {
    case simple = "0"
    case antiMistouch = "1"
    case unknown
}

enum SolixEvChargerSolarMode: String {
    case solarGrid = "0"
    case solarOnly = "1"
    case unknown
}

enum SolixScheduleWeekendMode: String {
    case same = "1"
    case different = "2"
    case unknown
}

enum Color: String {
    case black = "\u{001B}[30m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case cyan = "\u{001B}[36m"
    case mag = "\u{001B}[35m"
    case white = "\u{001B}[37m"
    case off = "\u{001B}[0m"
}

enum DeviceHexDataType: UInt8 {
    case str = 0x00
    case ui = 0x01
    case sile = 0x02
    case `var` = 0x03
    case bin = 0x04
    case sfle = 0x05
    case strb = 0x06
    case json = 0xFE
    case unk = 0xFF

    var byte: UInt8 { rawValue }
}

typealias DeviceHexDataTypes = DeviceHexDataType

// MARK: - Dataclasses (Structs)

struct SolarbankRatePlan {
    let unknown: String
    let smartmeter: String
    let smartplugs: String
    let manual: String
    let backup: String
    let useTime: String
    let smart: String
    let timeSlot: String

    static let `default` = SolarbankRatePlan(
        unknown: "",
        smartmeter: "",
        smartplugs: "blend_plan",
        manual: "custom_rate_plan",
        backup: "manual_backup",
        useTime: "use_time",
        smart: "",
        timeSlot: "time_slot"
    )
}

struct ApiEndpointServices {
    static let power = "power_service"
    static let charging = "charging_energy_service"
    static let hesService = "charging_hes_svc"
}

struct ApiCategories {
    static let accountInfo = "account_info"
    static let sitePrice = "site_price"
    static let deviceAutoUpgrade = "device_auto_upgrade"
    static let deviceTag = "device_tag"
    static let solarEnergy = "solar_energy"
    static let solarbankEnergy = "solarbank_energy"
    static let solarbankFittings = "solarbank_fittings"
    static let solarbankCutoff = "solarbank_cutoff"
    static let solarbankSolarInfo = "solarbank_solar_info"
    static let smartmeterEnergy = "smartmeter_energy"
    static let smartplugEnergy = "smartplug_energy"
    static let powerpanelEnergy = "powerpanel_energy"
    static let powerpanelAvgPower = "powerpanel_avg_power"
    static let hesEnergy = "hes_energy"
    static let hesAvgPower = "hes_avg_power"
    static let mqttDevices = "mqtt_devices"
}

struct SolixDeviceNames {
    static let shem3 = "Shelly 3EM"
    static let shemp3 = "Shelly Pro 3EM"
    static let shpps = "Shelly Plus Plug S"
    static let ae100 = "Power Dock AE100"
}

struct SolixDeviceCapacity {
    static let map: [String: Int] = [
        "A110A": 100,
        "A110B": 72,
        "A17C0": 1600,
        "A17C1": 1600,
        "A17C2": 1600,
        "A17C3": 1600,
        "A17C5": 2688,
        "A1720": 256,
        "A1722": 288,
        "A1723": 288,
        "A1725": 230,
        "A1726": 288,
        "A1727": 192,
        "A1728": 288,
        "A1729": 230,
        "A1751": 512,
        "A1753": 768,
        "A1754": 768,
        "A1755": 768,
        "A1760": 1024,
        "A1761": 1056,
        "A1762": 1056,
        "A1763": 1024,
        "A1765": 1024,
        "AS100": 1024,
        "A1770": 1229,
        "A1771": 1229,
        "A1772": 1536,
        "A1780": 2048,
        "A1780_1": 2048,
        "A1780P": 2048,
        "A1781": 2560,
        "A1782": 3072,
        "A1783": 2048,
        "A1785": 2048,
        "A1790": 3840,
        "A1790_1": 3840,
        "A1790P": 3840,
        "A5220": 5000,
    ]
}

struct SolixSiteType {
    static let t0 = SolixDeviceType.virtual.rawValue
    static let t1 = SolixDeviceType.pps.rawValue
    static let t2 = SolixDeviceType.solarbank.rawValue
    static let t3 = SolixDeviceType.hes.rawValue
    static let t4 = SolixDeviceType.powerpanel.rawValue
    static let t5 = SolixDeviceType.solarbank.rawValue
    static let t6 = SolixDeviceType.hes.rawValue
    static let t7 = SolixDeviceType.hes.rawValue
    static let t8 = SolixDeviceType.hes.rawValue
    static let t9 = SolixDeviceType.hes.rawValue
    static let t10 = SolixDeviceType.solarbank.rawValue
    static let t11 = SolixDeviceType.solarbank.rawValue
    static let t12 = SolixDeviceType.solarbank.rawValue
    static let t13 = SolixDeviceType.solarbankPps.rawValue
    static let t14 = SolixDeviceType.evCharger.rawValue
    static let t15 = SolixDeviceType.solarbankPps.rawValue
    static let t16 = SolixDeviceType.charger.rawValue
    static let t17 = SolixDeviceType.powerbank.rawValue
    static let t18 = SolixDeviceType.solarbank.rawValue

    static let map: [Int: String] = [
        0: t0,
        1: t1,
        2: t2,
        3: t3,
        4: t4,
        5: t5,
        6: t6,
        7: t7,
        8: t8,
        9: t9,
        10: t10,
        11: t11,
        12: t12,
        13: t13,
        14: t14,
        15: t15,
        16: t16,
        17: t17,
        18: t18,
    ]
}

struct SolixDeviceCategory {
    static let map: [String: String] = [
        "A17C0": "\(SolixDeviceType.solarbank.rawValue)_1",
        "A17C1": "\(SolixDeviceType.solarbank.rawValue)_2",
        "A17C2": "\(SolixDeviceType.solarbank.rawValue)_2",
        "A17C3": "\(SolixDeviceType.solarbank.rawValue)_2",
        "A17C5": "\(SolixDeviceType.solarbank.rawValue)_3",
        "AE100": SolixDeviceType.combinerBox.rawValue,
        "A5140": SolixDeviceType.inverter.rawValue,
        "A5143": SolixDeviceType.inverter.rawValue,
        "A17X7": SolixDeviceType.smartmeter.rawValue,
        "A17X7US": SolixDeviceType.smartmeter.rawValue,
        "AE1R0": SolixDeviceType.smartmeter.rawValue,
        "SHEM3": SolixDeviceType.smartmeter.rawValue,
        "SHEMP3": SolixDeviceType.smartmeter.rawValue,
        "A17X8": SolixDeviceType.smartplug.rawValue,
        "SHPPS": SolixDeviceType.smartplug.rawValue,
        "A1720": SolixDeviceType.pps.rawValue,
        "A1722": SolixDeviceType.pps.rawValue,
        "A1723": SolixDeviceType.pps.rawValue,
        "A1725": SolixDeviceType.pps.rawValue,
        "A1726": SolixDeviceType.pps.rawValue,
        "A1727": SolixDeviceType.pps.rawValue,
        "A1728": SolixDeviceType.pps.rawValue,
        "A1729": SolixDeviceType.pps.rawValue,
        "A1751": SolixDeviceType.pps.rawValue,
        "A1753": SolixDeviceType.pps.rawValue,
        "A1754": SolixDeviceType.pps.rawValue,
        "A1755": SolixDeviceType.pps.rawValue,
        "A1760": SolixDeviceType.pps.rawValue,
        "A1761": SolixDeviceType.pps.rawValue,
        "A1762": SolixDeviceType.pps.rawValue,
        "A1763": SolixDeviceType.pps.rawValue,
        "A1765": SolixDeviceType.pps.rawValue,
        "AS100": SolixDeviceType.pps.rawValue,
        "A1770": SolixDeviceType.pps.rawValue,
        "A1771": SolixDeviceType.pps.rawValue,
        "A1772": SolixDeviceType.pps.rawValue,
        "A1780": SolixDeviceType.pps.rawValue,
        "A1780P": SolixDeviceType.pps.rawValue,
        "A1781": SolixDeviceType.pps.rawValue,
        "A1782": SolixDeviceType.solarbankPps.rawValue,
        "A1783": SolixDeviceType.solarbankPps.rawValue,
        "A1785": SolixDeviceType.solarbankPps.rawValue,
        "A17E1": SolixDeviceType.solarbankPps.rawValue,
        "A1790": SolixDeviceType.pps.rawValue,
        "A1790P": SolixDeviceType.pps.rawValue,
        "A17B1": SolixDeviceType.powerpanel.rawValue,
        "A5101": SolixDeviceType.hes.rawValue,
        "A5102": SolixDeviceType.hes.rawValue,
        "A5103": SolixDeviceType.hes.rawValue,
        "A5150": SolixDeviceType.hes.rawValue,
        "A5220": SolixDeviceType.hes.rawValue,
        "A5341": SolixDeviceType.hes.rawValue,
        "A5450": SolixDeviceType.hes.rawValue,
        "AX1S0": SolixDeviceType.hes.rawValue,
        "A17A0": SolixDeviceType.powercooler.rawValue,
        "A17A1": SolixDeviceType.powercooler.rawValue,
        "A17A2": SolixDeviceType.powercooler.rawValue,
        "A17A3": SolixDeviceType.powercooler.rawValue,
        "A17A4": SolixDeviceType.powercooler.rawValue,
        "A17A5": SolixDeviceType.powercooler.rawValue,
        "A1903": SolixDeviceType.charger.rawValue,
        "A2345": SolixDeviceType.charger.rawValue,
        "A2687": SolixDeviceType.charger.rawValue,
        "A25X7": SolixDeviceType.charger.rawValue,
        "A91B2": SolixDeviceType.charger.rawValue,
        "A110A": SolixDeviceType.powerbank.rawValue,
        "A110B": SolixDeviceType.powerbank.rawValue,
        "A110G": SolixDeviceType.powerbank.rawValue,
        "A1341": SolixDeviceType.powerbank.rawValue,
        "AX170": SolixDeviceType.powerbank.rawValue,
        "A5191": SolixDeviceType.evCharger.rawValue,
    ]
}

struct SolarbankDeviceMetrics {
    static let A17C0: Set<String> = []
    static let A17C1: Set<String> = [
        "sub_package_num", "solar_power_1", "solar_power_2", "solar_power_3", "solar_power_4",
        "ac_power", "to_home_load", "pei_heating_power", "power_limit", "power_limit_option",
    ]
    static let A17C2: Set<String> = [
        "sub_package_num", "bat_charge_power", "solar_power_1", "solar_power_2", "ac_power",
        "to_home_load", "pei_heating_power", "micro_inverter_power", "micro_inverter_power_limit",
        "micro_inverter_low_power_limit", "grid_to_battery_power", "other_input_power",
        "power_limit", "power_limit_option",
    ]
    static let A17C3: Set<String> = [
        "sub_package_num", "solar_power_1", "solar_power_2", "to_home_load",
        "pei_heating_power", "power_limit", "power_limit_option",
    ]
    static let A17C5: Set<String> = [
        "sub_package_num", "bat_charge_power", "solar_power_1", "solar_power_2", "solar_power_3",
        "solar_power_4",
        "ac_power", "to_home_load", "pei_heating_power", "grid_to_battery_power",
        "other_input_power",
        "power_limit", "pv_power_limit", "ac_input_limit", "power_limit_option",
    ]

    static let inverterOutputOptions: [String: [String]] = [
        "A5143": ["600", "800"],
        "A17C1": ["350", "600", "800", "1000"],
        "A17C2": ["350", "600", "800", "1000"],
        "A17C3": ["350", "600", "800", "1000"],
        "A17C5": ["350", "600", "800", "1200"],
    ]

    static let mpptInputOptions: [String: [String]] = [
        "A17C5": ["2000", "3600"]
    ]
}

struct SolixDefaults {
    static let presetMin = 100
    static let presetMax = 800
    static let presetDef = 100
    static let presetNoSchedule = 200
    static let presetMaxMultiSystem = 3600

    static let allowExport = true
    static let powerMode = SolarbankPowerMode.normal.rawValue
    static let usageMode = SolarbankUsageMode.manual.rawValue

    static let chargePriorityMin = 0
    static let chargePriorityMax = 100
    static let chargePriorityDef = 80

    static let dischargePriorityDef = SolarbankDischargePriorityMode.off.rawValue

    static let tariffDef = SolixTariffTypes.offPeak.rawValue
    static let tariffPriceDef = "0.00"
    static let tariffWeSame = true
    static let currencyDef = "€"

    static let requestDelayMin: Double = 0.0
    static let requestDelayMax: Double = 10.0
    static let requestDelayDef: Double = 0.3

    static let requestTimeoutMin = 5
    static let requestTimeoutMax = 60
    static let requestTimeoutDef = 10

    static let endpointLimitDef = 10

    static let triggerTimeoutMin = 30
    static let triggerTimeoutMax = 600
    static let triggerTimeoutDef = 300

    static let microInverterLimitMin = 0
    static let microInverterLimitMax = 800

    static let dynamicTariffPriceFee: [String: Double] = [
        "UK": 0.1131,
        "SE": 0.0643,
        "AT": 0.11332,
        "BE": 0.01316,
        "FR": 0.1329,
        "DE": 0.17895,
        "PL": 0.0786,
        "DEFAULT": 0,
    ]

    static let dynamicTariffSellFee: [String: Double] = [
        "UK": 0.03,
        "SE": 0.2,
        "AT": 0.0973,
        "BE": 0.01305,
        "FR": 0.127,
        "DE": 0.0794,
        "PL": 0,
        "DEFAULT": 0,
    ]

    static let dynamicTariffPriceVat: [String: Double] = [
        "UK": 5,
        "SE": 25,
        "AT": 20,
        "BE": 21,
        "FR": 20,
        "DE": 19,
        "PL": 23,
        "DEFAULT": 0,
    ]
}

struct SolarbankTimeslot {
    var startTime: Date
    var endTime: Date
    var applianceLoad: Int?
    var deviceLoad: Int?
    var allowExport: Bool?
    var chargePriorityLimit: Int?
    var dischargePriority: Int?
}

struct Solarbank2Timeslot {
    var startTime: Date?
    var endTime: Date?
    var applianceLoad: Int?
    var weekdays: Set<String>?
}

struct SolixPriceProvider: CustomStringConvertible {
    var country: String?
    var company: String?
    var area: String?

    init(provider: [String: String]) {
        self.country = provider["country"]
        self.company = provider["company"]
        self.area = provider["area"]
    }

    init(provider: String) {
        let keys = provider.split(separator: "/").map(String.init)
        self.country = keys.indices.contains(0) && keys[0] != "-" ? keys[0] : nil
        self.company = keys.indices.contains(1) && keys[1] != "-" ? keys[1] : nil
        self.area = keys.indices.contains(2) && keys[2] != "-" ? keys[2] : nil
    }

    init(provider: Any?) {
        if let dict = provider as? [String: String] {
            self.country = dict["country"]
            self.company = dict["company"]
            self.area = dict["area"]
        } else if let string = provider as? String {
            let keys = string.split(separator: "/").map(String.init)
            self.country = keys.indices.contains(0) && keys[0] != "-" ? keys[0] : nil
            self.company = keys.indices.contains(1) && keys[1] != "-" ? keys[1] : nil
            self.area = keys.indices.contains(2) && keys[2] != "-" ? keys[2] : nil
        } else if let dict = provider as? [String: Any] {
            self.country = dict["country"] as? String
            self.company = dict["company"] as? String
            self.area = dict["area"] as? String
        } else {
            self.country = nil
            self.company = nil
            self.area = nil
        }
    }

    var description: String {
        "\(country ?? "-")/\(company ?? "-")/\(area ?? "-")"
    }

    func asDictionary() -> [String: String?] {
        ["country": country, "company": company, "area": area]
    }
}

struct SolixVehicle: CustomStringConvertible {
    var brand: String
    var model: String
    var productiveYear: Int
    var modelId: Int?
    var batteryCapacity: Double
    var acMaxChargingPower: Double
    var energyConsumptionPer100km: Double

    init(
        brand: String = "", model: String = "", productiveYear: Int = 0, modelId: Int? = nil,
        batteryCapacity: Double = 0, acMaxChargingPower: Double = 0,
        energyConsumptionPer100km: Double = 0
    ) {
        self.brand = brand
        self.model = model
        self.productiveYear = productiveYear
        self.modelId = modelId
        self.batteryCapacity = batteryCapacity
        self.acMaxChargingPower = acMaxChargingPower
        self.energyConsumptionPer100km = energyConsumptionPer100km
    }

    init(vehicle: [String: Any]) {
        self.brand = vehicle["brand"] as? String ?? vehicle["brand_name"] as? String ?? ""
        self.model = vehicle["model"] as? String ?? vehicle["model_name"] as? String ?? ""
        if let year = vehicle["productive_year"] as? Int {
            self.productiveYear = year
        } else if let yearStr = vehicle["productive_year"] as? String, let year = Int(yearStr) {
            self.productiveYear = year
        } else {
            self.productiveYear = 0
        }
        if let mid = vehicle["id"] as? Int ?? vehicle["model_id"] as? Int {
            self.modelId = mid
        } else if let midStr = vehicle["id"] as? String ?? vehicle["model_id"] as? String,
            let mid = Int(midStr)
        {
            self.modelId = mid
        } else {
            self.modelId = nil
        }
        self.batteryCapacity = (vehicle["battery_capacity"] as? Double) ?? 0
        self.acMaxChargingPower =
            (vehicle["ac_max_charging_power"] as? Double) ?? (vehicle["ac_max_power"] as? Double)
            ?? 0
        self.energyConsumptionPer100km =
            (vehicle["energy_consumption_per_100km"] as? Double)
            ?? (vehicle["hundred_fuel_consumption"] as? Double) ?? 0
    }

    init(vehicle: String) {
        let keys = vehicle.split(separator: "/").map(String.init)
        self.brand = keys.indices.contains(0) && keys[0] != "-" ? keys[0] : ""
        self.model = keys.indices.contains(1) && keys[1] != "-" ? keys[1] : ""
        if keys.indices.contains(2), let year = Int(keys[2]) {
            self.productiveYear = year
        } else {
            self.productiveYear = 0
        }
        if keys.indices.contains(3), let mid = Int(keys[3]) {
            self.modelId = mid
        } else {
            self.modelId = nil
        }
        self.batteryCapacity = 0
        self.acMaxChargingPower = 0
        self.energyConsumptionPer100km = 0
    }

    var description: String {
        "\(brand.isEmpty ? "-" : brand)/\(model.isEmpty ? "-" : model)/\(productiveYear == 0 ? "-" : String(productiveYear))"
    }

    func idAttributes() -> String {
        "\(modelId == nil ? "-" : String(modelId!))/\(batteryCapacity == 0 ? "-" : String(batteryCapacity)) kWh/\(acMaxChargingPower == 0 ? "-" : String(acMaxChargingPower)) kW"
    }

    func asDictionary(skipEmpty: Bool = false) -> [String: Any] {
        var dict: [String: Any] = [
            "brand": brand,
            "model": model,
            "productive_year": productiveYear,
            "model_id": modelId as Any,
            "battery_capacity": batteryCapacity,
            "ac_max_charging_power": acMaxChargingPower,
            "energy_consumption_per_100km": energyConsumptionPer100km,
        ]
        if skipEmpty {
            dict = dict.filter { key, value in
                if key == "model_id" { return modelId != nil }
                if let str = value as? String { return !str.isEmpty }
                if let num = value as? Int { return num != 0 }
                if let num = value as? Double { return num != 0 }
                return true
            }
        }
        return dict
    }
}

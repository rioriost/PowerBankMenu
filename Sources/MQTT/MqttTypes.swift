//
//  MqttTypes.swift
//  PowerBankMenu
//
//  Swift port of anker-solix-api/api/mqtttypes.py (core hex types + basic decoding)
//

import Foundation

// MARK: - Helpers

extension Data {
    fileprivate init(hexString: String) {
        var data = Data()
        var temp = ""
        for (index, char) in hexString.enumerated() {
            temp.append(char)
            if index % 2 == 1 {
                if let byte = UInt8(temp, radix: 16) {
                    data.append(byte)
                }
                temp = ""
            }
        }
        self = data
    }

    fileprivate func toHexString(sep: String = "") -> String {
        if sep.isEmpty {
            return map { String(format: "%02x", $0) }.joined()
        }
        return map { String(format: "%02x", $0) }.joined(separator: sep)
    }

    fileprivate func safeSubdata(in range: Range<Int>) -> Data? {
        guard range.lowerBound >= 0,
            range.upperBound >= range.lowerBound,
            range.upperBound <= count
        else { return nil }
        return Data(self[range])
    }

    fileprivate func safeByte(at index: Int) -> UInt8? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}

extension UInt8 {
    fileprivate var byte: UInt8 { self }
}

extension Array where Element == UInt8 {
    fileprivate func toData() -> Data { Data(self) }
}

// MARK: - Device Hex Data Header

struct DeviceHexDataHeader: CustomStringConvertible {
    var prefix: Data = Data()
    var msglength: Int = 0
    var pattern: Data = Data()
    var msgtype: Data = Data()
    var increment: Data = Data()

    init(hexbytes: Data? = nil, cmdMsg: Data? = nil) {
        if let hexbytes, hexbytes.count >= 9 {
            guard let prefixData = hexbytes.safeSubdata(in: 0..<2),
                let lenData = hexbytes.safeSubdata(in: 2..<4),
                let patternData = hexbytes.safeSubdata(in: 4..<7),
                let msgTypeData = hexbytes.safeSubdata(in: 7..<9)
            else { return }
            prefix = prefixData
            msglength = Int(
                UInt16(
                    littleEndian: lenData.withUnsafeBytes {
                        $0.load(as: UInt16.self)
                    }))
            pattern = patternData
            msgtype = msgTypeData

            if hexbytes.count >= 10, let incr = hexbytes.safeSubdata(in: 9..<10) {
                let disallowed = Data([0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9])
                increment = disallowed.contains(incr) ? Data() : incr
            }
        } else if let cmdMsg, cmdMsg.count >= 2 {
            prefix = Data(hexString: "ff09")
            pattern = Data(hexString: "03000f")
            msgtype = cmdMsg.subdata(in: 0..<2)
            increment = cmdMsg.count >= 3 ? cmdMsg.subdata(in: 2..<3) : Data()
            msglength = length + 2
        }
    }

    var length: Int {
        return prefix.count
            + pattern.count
            + msgtype.count
            + increment.count
            + (msglength > 0 ? 2 : 0)
    }

    var description: String {
        "prefix:\(prefix.toHexString()), msglength:\(msglength), pattern:\(pattern.toHexString()), msgtype:\(msgtype.toHexString()), increment:\(increment.toHexString())"
    }

    func hexString(sep: String = "") -> String {
        let bytes =
            prefix
            + withUnsafeBytes(of: UInt16(msglength).littleEndian) { Data($0) }
            + pattern
            + msgtype
            + increment
        return bytes.toHexString(sep: sep)
    }
}

// MARK: - Device Hex Data Field

struct DeviceHexDataField: CustomStringConvertible {
    var fName: Data = Data()
    var fLength: Int = 0
    var fType: Data = Data()
    var fValue: Data = Data()
    private(set) var json: [String: Any] = [:]
    private var lengthBytes: Int = 1

    init(hexbytes: Data? = nil) {
        guard let hexbytes, hexbytes.count >= 2 else { return }

        fName = Data(hexbytes.prefix(1))

        let len2: Int?
        if hexbytes.count >= 3, let lenData = hexbytes.safeSubdata(in: 1..<3) {
            len2 = Int(
                UInt16(
                    littleEndian: lenData.withUnsafeBytes {
                        $0.load(as: UInt16.self)
                    }
                )
            )
        } else {
            len2 = nil
        }
        if let len2,
            hexbytes.count > 3,
            hexbytes.safeSubdata(in: 3..<4) == Data([DeviceHexDataType.str.rawValue]),
            len2 > 255, (4 + len2) <= hexbytes.count
        {
            lengthBytes = 2
            fLength = len2
        } else {
            if let lenByte = hexbytes.safeByte(at: 1) {
                fLength = Int(lenByte)
            } else {
                fLength = 0
            }
        }

        if fLength > 1 {
            if lengthBytes > 1 {
                let end = 3 + fLength
                guard hexbytes.count >= end, hexbytes.count >= 4 else { return }
                guard let typeData = hexbytes.safeSubdata(in: 3..<4) else { return }
                fType = typeData
                guard end >= 4, let valueData = hexbytes.safeSubdata(in: 4..<end) else { return }
                fValue = valueData
            } else {
                let end = 2 + fLength
                guard hexbytes.count >= end, hexbytes.count >= 3 else { return }
                guard let typeData = hexbytes.safeSubdata(in: 2..<3) else { return }
                fType = typeData
                guard end >= 3, let valueData = hexbytes.safeSubdata(in: 3..<end) else { return }
                fValue = valueData
            }
            checkJson()
        } else if fLength == 1 {
            guard hexbytes.count >= 3 else { return }
            fType = Data()
            guard let valueData = hexbytes.safeSubdata(in: 2..<(2 + fLength)) else { return }
            fValue = valueData
        }
    }

    var length: Int {
        return fName.count + fType.count + fValue.count + (fLength > 0 ? lengthBytes : 0)
    }

    var description: String {
        "f_name:\(fName.toHexString()), f_length:\(fLength), f_type:\(fType.toHexString()), f_value:\(fValue.toHexString(sep: ":"))"
    }

    func uintLE() -> UInt64? {
        guard !fValue.isEmpty, fValue.count <= 8 else { return nil }
        var result: UInt64 = 0
        for (index, byte) in fValue.enumerated() {
            result |= UInt64(byte) << (8 * index)
        }
        return result
    }

    func intLE() -> Int64? {
        guard let u = uintLE() else { return nil }
        let bitWidth = fValue.count * 8
        if bitWidth == 0 { return nil }
        if bitWidth >= 64 { return Int64(bitPattern: u) }
        let signMask = UInt64(1) << (bitWidth - 1)
        if (u & signMask) != 0 {
            let maxVal = UInt64(1) << bitWidth
            return Int64(bitPattern: u) - Int64(maxVal)
        }
        return Int64(u)
    }

    func floatLE() -> Float? {
        guard fValue.count == 4 else { return nil }
        return fValue.withUnsafeBytes { $0.load(as: Float.self) }
    }

    func doubleLE() -> Double? {
        guard fValue.count == 8 else { return nil }
        return fValue.withUnsafeBytes { $0.load(as: Double.self) }
    }

    func stringValue() -> String? {
        guard
            fType == Data([DeviceHexDataType.str.rawValue])
                || fType == Data([DeviceHexDataType.json.rawValue])
        else { return nil }
        return String(data: fValue, encoding: .utf8)
    }

    func jsonValue() -> [String: Any]? {
        guard !json.isEmpty else { return nil }
        return json
    }

    func boolValue() -> Bool? {
        if let intVal = intLE() { return intVal != 0 }
        if let str = stringValue()?.lowercased() {
            if ["true", "yes", "on", "1"].contains(str) { return true }
            if ["false", "no", "off", "0"].contains(str) { return false }
        }
        return nil
    }

    mutating func update(
        value: Any?,
        name: String?,
        fieldtype: UInt8?,
        desc: [String: Any]? = nil
    ) -> DeviceHexDataField? {
        let desc = desc ?? [:]

        if let name, !name.isEmpty {
            let cleaned = name.count == 1 ? "0\(name)" : name
            let nameData = Data(hexString: cleaned.lowercased())
            if !nameData.isEmpty {
                fName = nameData.prefix(1)
            }
        }

        guard !fName.isEmpty else { return nil }

        if let fieldtype, let typed = DeviceHexDataType(rawValue: fieldtype) {
            fType = typed == .unk ? Data() : Data([typed.rawValue])
        } else {
            fType = Data()
        }

        guard let type = DeviceHexDataType(rawValue: fieldtype ?? DeviceHexDataType.unk.rawValue)
        else {
            return nil
        }
        guard let encoded = encodeValue(value: value, fieldtype: type, desc: desc) else {
            return nil
        }

        fValue = encoded
        fLength = fType.count + fValue.count
        if fLength > 255 {
            lengthBytes = 2
        }
        checkJson()
        return self
    }

    private func encodeValue(
        value: Any?,
        fieldtype: DeviceHexDataType,
        desc: [String: Any]
    ) -> Data? {
        func numberValue(_ value: Any?) -> Double? {
            if let v = value as? Double { return v }
            if let v = value as? Float { return Double(v) }
            if let v = value as? Int { return Double(v) }
            if let v = value as? Int64 { return Double(v) }
            if let v = value as? UInt { return Double(v) }
            if let v = value as? UInt64 { return Double(v) }
            if let v = value as? String { return Double(v) }
            if let v = value as? Bool { return v ? 1 : 0 }
            return nil
        }

        var fieldValue: Any? = value

        if let name = desc[MqttMapKeys.name] as? String, name.hasSuffix("_time"),
            let str = value as? String, let timeBytes = convertTimeStringToBytes(str)
        {
            fieldValue = timeBytes
        }

        if fieldValue == nil {
            fieldValue = desc[MqttMapKeys.valueDefault]
        }

        guard let finalValue = fieldValue else {
            return nil
        }

        let minValue = numberValue(desc[MqttMapKeys.valueMin])
        let maxValue = numberValue(desc[MqttMapKeys.valueMax])
        let stepValue = numberValue(desc[MqttMapKeys.valueStep])
        let options = desc[MqttMapKeys.valueOptions]

        if options != nil || minValue != nil || maxValue != nil || stepValue != nil {
            let validator = MqttCmdValidator(
                min: minValue ?? 0,
                max: maxValue ?? 0,
                step: stepValue ?? 0,
                options: options
            )
            guard let validated = validator.check(finalValue) else {
                return nil
            }
            fieldValue = validated
        }

        let divider = numberValue(desc[MqttMapKeys.valueDivider]) ?? 1

        switch fieldtype {
        case .str:
            if let data = fieldValue as? Data { return data }
            let text = String(describing: fieldValue)
            var data = text.data(using: .utf8) ?? Data()
            if let length = desc[MqttMapKeys.length] as? Int, length > data.count {
                data.append(Data(repeating: 0x00, count: max(0, length - data.count)))
            }
            return data
        case .ui:
            guard let num = numberValue(fieldValue) else { return nil }
            let val = UInt64(max(0, num / divider))
            return Data([UInt8(val & 0xFF)])
        case .sile:
            if let data = fieldValue as? Data {
                return data.suffix(2)
            }
            guard let num = numberValue(fieldValue) else { return nil }
            let signed = desc[MqttMapKeys.signed] as? Bool ?? true
            let intVal = Int64(num / divider)
            let packed = signed ? UInt64(bitPattern: intVal) : UInt64(max(0, intVal))
            return Data([UInt8(packed & 0xFF), UInt8((packed >> 8) & 0xFF)])
        case .var:
            if let data = fieldValue as? Data {
                let targetLength = (desc[MqttMapKeys.length] as? Int) ?? 4
                let padded = Data(repeating: 0x00, count: max(0, targetLength - data.count)) + data
                return padded.suffix(targetLength)
            }
            guard let num = numberValue(fieldValue) else { return nil }
            let signed = desc[MqttMapKeys.signed] as? Bool ?? true
            let intVal = Int64(num / divider)
            let packed = signed ? UInt64(bitPattern: intVal) : UInt64(max(0, intVal))
            return Data([
                UInt8(packed & 0xFF),
                UInt8((packed >> 8) & 0xFF),
                UInt8((packed >> 16) & 0xFF),
                UInt8((packed >> 24) & 0xFF),
            ])
        case .sfle:
            guard let num = numberValue(fieldValue) else { return nil }
            var bits = Float(num / divider).bitPattern.littleEndian
            return withUnsafeBytes(of: &bits) { Data($0) }
        case .json:
            if let data = fieldValue as? Data { return data }
            if let dict = fieldValue as? [String: Any],
                let json = try? JSONSerialization.data(withJSONObject: dict, options: [])
            {
                return json
            }
            if let text = fieldValue as? String {
                return text.data(using: .utf8)
            }
            return nil
        case .bin, .strb, .unk:
            return nil
        }
    }

    func hexString(sep: String = "") -> String {
        var bytes = Data()
        bytes.append(fName)
        let lenBytes = withUnsafeBytes(of: UInt16(fLength).littleEndian) { Data($0) }
        bytes.append(lengthBytes > 1 ? lenBytes : lenBytes.prefix(1))
        bytes.append(fType)
        bytes.append(fValue)
        return bytes.toHexString(sep: sep)
    }

    private mutating func checkJson() {
        guard
            fType == Data([DeviceHexDataType.str.rawValue])
                || fType == Data([DeviceHexDataType.json.rawValue])
        else { return }
        if let text = String(data: fValue, encoding: .utf8),
            text.hasPrefix("{") || text.hasPrefix("["),
            let data = text.data(using: .utf8),
            let obj = try? JSONSerialization.jsonObject(with: data),
            let dict = obj as? [String: Any]
        {
            json = dict
            fType = Data([DeviceHexDataType.json.rawValue])
        }
    }
}

// MARK: - Device Hex Data

struct DeviceHexData: CustomStringConvertible {
    var hexbytes: Data = Data()
    var model: String = ""
    var length: Int = 0
    var msgHeader: DeviceHexDataHeader = DeviceHexDataHeader()
    var msgFields: [String: DeviceHexDataField] = [:]
    var checksum: Data = Data()

    init(model: String = "", msgHeader: DeviceHexDataHeader) {
        self.model = model
        self.msgHeader = msgHeader
        self.msgFields = [:]
        self.hexbytes = Data()
        self.length = 0
        self.checksum = Data()
    }

    init(hexbytes: Data, model: String = "") {
        self.hexbytes = hexbytes
        self.model = model
        decode()
    }

    init(hexString: String, model: String = "") {
        self.hexbytes = Data(hexString: hexString.replacingOccurrences(of: ":", with: ""))
        self.model = model
        decode()
    }

    private mutating func decode() {
        guard !hexbytes.isEmpty else { return }

        length = hexbytes.count
        checksum = hexbytes.suffix(1)
        msgHeader = DeviceHexDataHeader(hexbytes: hexbytes.prefix(10))

        var idx = msgHeader.length
        msgFields = [:]

        while idx >= 9 && idx < length - 1 {
            let remaining = length - idx
            guard remaining >= 2 else { break }
            guard idx >= 0, idx < length else { break }
            let fieldBytes = Data(hexbytes[idx...])
            let field = DeviceHexDataField(hexbytes: fieldBytes)
            guard field.length > 0, field.length <= remaining else { break }
            if !field.fName.isEmpty {
                msgFields[field.fName.toHexString()] = field
                idx += field.length
            } else {
                break
            }
        }
    }

    var description: String {
        "model:\(model), header:{\(msgHeader)}, hexbytes:\(hexbytes.toHexString()), checksum:\(checksum.toHexString())"
    }

    func hexString(sep: String = "") -> String {
        hexbytes.toHexString(sep: sep)
    }

    func xorChecksum() -> Data {
        var checksum: UInt8 = 0
        for b in hexbytes {
            checksum ^= b
        }
        return Data([checksum])
    }

    func decodedValues() -> [String: Any] {
        var output: [String: Any] = [:]

        for (key, field) in msgFields {
            if let json = field.jsonValue() {
                output[key] = json
                continue
            }
            if let text = field.stringValue() {
                output[key] = text
                continue
            }
            if let floatValue = field.floatLE() {
                output[key] = floatValue
                continue
            }
            if let doubleValue = field.doubleLE() {
                output[key] = doubleValue
                continue
            }
            if let intValue = field.intLE() {
                output[key] = intValue
                continue
            }
            if let uintValue = field.uintLE() {
                output[key] = uintValue
                continue
            }
            output[key] = field.fValue.toHexString()
        }

        return output
    }

    func decodedValuesExpanded() -> [String: Any] {
        var output = decodedValues()
        guard !model.isEmpty else { return output }

        let modelMap = MqttMap.map[model] ?? [:]
        for (_, fieldsAny) in modelMap {
            for (fieldKey, descAny) in fieldsAny {
                guard let desc = descAny as? [String: Any] else { continue }

                if let name = desc[MqttMapKeys.name] as? String, let value = output[fieldKey] {
                    output[name] = value
                }

                if let bytesAny = desc[MqttMapKeys.bytes] as? [String: Any],
                    let field = msgFields[fieldKey]
                {
                    let fieldBytes = field.fValue
                    for (offsetKey, subDescAny) in bytesAny {
                        guard let subDesc = subDescAny as? [String: Any] else { continue }
                        guard let subName = subDesc[MqttMapKeys.name] as? String else { continue }
                        let offset = Int(offsetKey, radix: 16) ?? Int(offsetKey) ?? 0
                        guard offset >= 0, offset < fieldBytes.count else { continue }
                        let type = parseFieldType(subDesc[MqttMapKeys.type])
                        let length = decodeLength(for: type, desc: subDesc, available: fieldBytes.count - offset)
                        guard length > 0, offset + length <= fieldBytes.count else { continue }
                        let slice = fieldBytes.subdata(in: offset..<(offset + length))
                        if let value = decodeValue(slice, type: type, desc: subDesc) {
                            output[subName] = value
                        }
                    }
                }

                if let jsonMap = desc[MqttMapKeys.json] as? [String: Any],
                    let dict = output[fieldKey] as? [String: Any]
                {
                    applyJsonMap(jsonMap, source: dict, output: &output)
                }
            }
        }

        return output
    }

    private func applyJsonMap(_ map: [String: Any], source: [String: Any], output: inout [String: Any]) {
        for (key, valueAny) in map {
            guard let valueMap = valueAny as? [String: Any] else { continue }
            if let name = valueMap[MqttMapKeys.name] as? String, let found = source[key] {
                output[name] = found
            }
            if let nestedMap = valueMap as? [String: Any],
                let nestedSource = source[key] as? [String: Any]
            {
                applyJsonMap(nestedMap, source: nestedSource, output: &output)
            }
        }
    }

    private func parseFieldType(_ value: Any?) -> UInt8? {
        if let v = value as? UInt8 { return v }
        if let v = value as? Int { return UInt8(v) }
        if let v = value as? String { return UInt8(Int(v) ?? 0) }
        return nil
    }

    private func decodeLength(for type: UInt8?, desc: [String: Any], available: Int) -> Int {
        if let length = desc[MqttMapKeys.length] as? Int {
            return min(length, available)
        }
        guard let type, let dataType = DeviceHexDataType(rawValue: type) else {
            return min(available, 1)
        }
        switch dataType {
        case .ui:
            return min(available, 1)
        case .sile:
            return min(available, 2)
        case .var:
            return min(available, 4)
        case .sfle:
            return min(available, 4)
        case .str:
            return available
        case .json:
            return available
        default:
            return min(available, 1)
        }
    }

    private func decodeValue(_ data: Data, type: UInt8?, desc: [String: Any]) -> Any? {
        let factor = (desc[MqttMapKeys.factor] as? Double) ?? 1
        let signed = (desc[MqttMapKeys.signed] as? Bool) ?? true
        guard let type, let dataType = DeviceHexDataType(rawValue: type) else {
            if let intVal = data.last {
                return Double(intVal) * factor
            }
            return nil
        }

        switch dataType {
        case .ui:
            let value = Double(data.first ?? 0)
            return value * factor
        case .sile:
            guard data.count >= 2 else { return nil }
            let raw = UInt16(littleEndian: data.withUnsafeBytes { $0.load(as: UInt16.self) })
            let signedValue = signed ? Int16(bitPattern: raw) : Int16(raw)
            return Double(signedValue) * factor
        case .var:
            guard data.count >= 4 else { return nil }
            let raw = UInt32(littleEndian: data.withUnsafeBytes { $0.load(as: UInt32.self) })
            let signedValue = signed ? Int32(bitPattern: raw) : Int32(raw)
            return Double(signedValue) * factor
        case .sfle:
            guard data.count >= 4 else { return nil }
            let value = data.withUnsafeBytes { $0.load(as: Float.self) }
            return Double(value) * factor
        case .str:
            return String(data: data, encoding: .utf8)
        case .json:
            if let obj = try? JSONSerialization.jsonObject(with: data),
                let dict = obj as? [String: Any]
            {
                return dict
            }
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }

    mutating func updateField(_ datafield: DeviceHexDataField) {
        guard !datafield.fName.isEmpty else { return }
        msgFields[datafield.fName.toHexString()] = datafield
        let sortedKeys = msgFields.keys.sorted()
        msgFields = Dictionary(
            uniqueKeysWithValues: sortedKeys.compactMap { key in
                guard let value = msgFields[key] else { return nil }
                return (key, value)
            })
        updateHexbytes()
    }

    mutating func addTimestampField(
        fieldname: String = "fe",
        fieldtype: UInt8? = DeviceHexDataType.`var`.rawValue
    ) {
        guard let value = convertTimestamp(Date().timeIntervalSince1970, ms: false) else { return }
        var field = DeviceHexDataField()
        field.fName = Data(hexString: fieldname)
        if let fieldtype, fieldtype != DeviceHexDataType.unk.rawValue {
            field.fType = Data([fieldtype])
        } else {
            field.fType = Data()
        }
        field.fValue = value
        field.fLength = field.fType.count + field.fValue.count
        updateField(field)
    }

    mutating func addTimestampMsField(fieldname: String = "fd") {
        guard let value = convertTimestamp(Date().timeIntervalSince1970, ms: true) else { return }
        var field = DeviceHexDataField()
        field.fName = Data(hexString: fieldname)
        field.fType = Data([DeviceHexDataType.str.rawValue])
        field.fValue = value
        field.fLength = field.fType.count + field.fValue.count
        updateField(field)
    }

    @discardableResult
    mutating func popField(_ datafield: String) -> DeviceHexDataField? {
        let key = datafield.lowercased()
        let removed = msgFields.removeValue(forKey: key)
        updateHexbytes()
        return removed
    }

    private mutating func updateHexbytes() {
        var header = msgHeader
        var fieldsData = Data()
        var totalLength = header.length

        for key in msgFields.keys.sorted() {
            if let field = msgFields[key] {
                totalLength += field.length
                fieldsData.append(Data(hexString: field.hexString()))
            }
        }

        totalLength += 1
        header.msglength = totalLength
        msgHeader = header

        var packet = Data(hexString: header.hexString())
        packet.append(fieldsData)

        let checksumData = xorChecksum(data: packet)
        packet.append(checksumData)

        hexbytes = packet
        checksum = checksumData
        length = packet.count
    }

    private func xorChecksum(data: Data) -> Data {
        var checksum: UInt8 = 0
        for b in data {
            checksum ^= b
        }
        return Data([checksum])
    }
}

private struct MqttCmdValidator {
    let min: Double
    let max: Double
    let step: Double
    let options: Any?

    func check(_ value: Any) -> Any? {
        if let options = options as? [Any] {
            if options.contains(where: { String(describing: $0) == String(describing: value) }) {
                return value
            }
            return nil
        }

        if let options = options as? [String: Any] {
            if let str = value as? String {
                if let mapped = options[str] ?? options[str.lowercased()] {
                    return mapped
                }
            }
            if options.values.contains(where: {
                String(describing: $0) == String(describing: value)
            }) {
                return value
            }
            return nil
        }

        if let options = options as? [AnyHashable: Any] {
            if let str = value as? String {
                if let mapped = options[str] ?? options[str.lowercased()] {
                    return mapped
                }
                if let intVal = Int(str), let mapped = options[intVal] {
                    return mapped
                }
            }
            if let intVal = value as? Int, let mapped = options[intVal] {
                return mapped
            }
            if let doubleVal = value as? Double, let mapped = options[doubleVal] {
                return mapped
            }
            if options.values.contains(where: {
                String(describing: $0) == String(describing: value)
            }) {
                return value
            }
            return nil
        }

        if let num = numberValue(value) {
            if min < max && !(min...max).contains(num) {
                return nil
            }
            if step > 0 {
                let rounded = ApiHelpers.roundByFactor(step * round(num / step), factor: step)
                return rounded
            }
            return num
        }

        if min > 0 || max > 0 {
            return nil
        }
        return value
    }

    private func numberValue(_ value: Any) -> Double? {
        if let v = value as? Double { return v }
        if let v = value as? Float { return Double(v) }
        if let v = value as? Int { return Double(v) }
        if let v = value as? Int64 { return Double(v) }
        if let v = value as? UInt { return Double(v) }
        if let v = value as? UInt64 { return Double(v) }
        if let v = value as? String { return Double(v) }
        if let v = value as? Bool { return v ? 1 : 0 }
        return nil
    }
}

private func convertTimestamp(_ value: Any, ms: Bool = false) -> Data? {
    if let num = value as? Double {
        if ms {
            return String(Int(num * 1000)).data(using: .utf8)
        }
        let intVal = Int64(num)
        let packed = UInt64(bitPattern: intVal)
        return Data([
            UInt8(packed & 0xFF),
            UInt8((packed >> 8) & 0xFF),
            UInt8((packed >> 16) & 0xFF),
            UInt8((packed >> 24) & 0xFF),
        ])
    }
    if let num = value as? Int {
        return convertTimestamp(Double(num), ms: ms)
    }
    return nil
}

private func convertTimeStringToBytes(_ value: String) -> Data? {
    let parts = value.split(separator: ":").map { String($0) }
    guard parts.count == 2 || parts.count == 3 else { return nil }
    let nums = parts.compactMap { Int($0) }
    guard nums.count == parts.count else { return nil }

    if nums.count == 2 {
        let minutes = UInt8(nums[1] & 0xFF)
        let hours = UInt8(nums[0] & 0xFF)
        return Data([minutes, hours])
    }

    let seconds = UInt8(nums[2] & 0xFF)
    let minutes = UInt8(nums[1] & 0xFF)
    let hours = UInt8(nums[0] & 0xFF)
    return Data([seconds, minutes, hours])
}

func generateMqttCommand(
    command: String = SolixMqttCommands.realtimeTrigger,
    parameters: [String: Any]? = nil,
    model: String? = nil
) -> DeviceHexData? {
    let params = parameters ?? [:]
    var msgtype = ""
    var fields: [String: Any] = [:]

    func parseCommandList(_ value: Any?) -> [String] {
        if let list = value as? [String] { return list }
        if let list = value as? [Any] {
            return list.compactMap { $0 as? String }
        }
        return []
    }

    func parseFieldType(_ value: Any?) -> UInt8? {
        if let v = value as? UInt8 { return v }
        if let v = value as? Int { return UInt8(v) }
        if let v = value as? String {
            if let intVal = Int(v) { return UInt8(intVal) }
        }
        return nil
    }

    if let model, let pnMap = MqttMap.map[model] {
        for (key, value) in pnMap {
            let map = value
            let commandName = map[MqttMapKeys.commandName] as? String
            let commandList = parseCommandList(map[MqttMapKeys.commandList])
            if commandName == command || commandList.contains(command) {
                msgtype = key
                fields = map
                break
            }
        }
    }

    if !fields.isEmpty {
        if let nested = fields[command] as? [String: Any] {
            fields = nested
        }
        let byteFields = fields.filter { $0.key.count <= 2 }
        if !byteFields.isEmpty {
            let header = DeviceHexDataHeader(cmdMsg: Data(hexString: msgtype))
            var hexdata = DeviceHexData(model: model ?? "", msgHeader: header)

            for (field, descAny) in byteFields.sorted(by: { $0.key < $1.key }) {
                guard let desc = descAny as? [String: Any] else { continue }
                let fieldName =
                    field.lowercased().count == 1 ? "0\(field.lowercased())" : field.lowercased()

                if let name = desc[MqttMapKeys.name] as? String, name == "pattern_22" {
                    let bytes = Data(hexString: "\(fieldName)0122")
                    hexdata.updateField(DeviceHexDataField(hexbytes: bytes))
                    continue
                }

                if let name = desc[MqttMapKeys.name] as? String, name == "msg_timestamp" {
                    let fieldtype = parseFieldType(desc[MqttMapKeys.type])
                    if fieldName == "fd" {
                        hexdata.addTimestampMsField(fieldname: fieldName)
                    } else {
                        hexdata.addTimestampField(fieldname: fieldName, fieldtype: fieldtype)
                    }
                    continue
                }

                let paramKey =
                    (desc[MqttMapKeys.valueFollows] as? String)
                    ?? (desc[MqttMapKeys.name] as? String)

                let value = paramKey.flatMap { params[$0] }
                let fieldtype = parseFieldType(desc[MqttMapKeys.type])

                var dataField = DeviceHexDataField()
                guard
                    dataField.update(
                        value: value,
                        name: fieldName,
                        fieldtype: fieldtype,
                        desc: desc
                    ) != nil
                else {
                    continue
                }
                hexdata.updateField(dataField)
            }
            return hexdata
        }
    } else if command == SolixMqttCommands.realtimeTrigger {
        let header = DeviceHexDataHeader(cmdMsg: Data(hexString: "0057"))
        var hexdata = DeviceHexData(model: model ?? "", msgHeader: header)
        hexdata.updateField(DeviceHexDataField(hexbytes: Data(hexString: "a10122")))

        let timeout =
            params["timeout"]
            ?? params["trigger_timeout_sec"]
            ?? 60

        var fieldA2 = DeviceHexDataField()
        _ = fieldA2.update(
            value: 1,
            name: "a2",
            fieldtype: DeviceHexDataType.ui.rawValue,
            desc: [MqttMapKeys.type: DeviceHexDataType.ui.rawValue]
        )
        hexdata.updateField(fieldA2)

        var fieldA3 = DeviceHexDataField()
        _ = fieldA3.update(
            value: timeout,
            name: "a3",
            fieldtype: DeviceHexDataType.`var`.rawValue,
            desc: [MqttMapKeys.type: DeviceHexDataType.`var`.rawValue]
        )
        hexdata.updateField(fieldA3)

        hexdata.addTimestampField()
        return hexdata
    } else if command == SolixMqttCommands.statusRequest {
        let header = DeviceHexDataHeader(cmdMsg: Data(hexString: "0040"))
        var hexdata = DeviceHexData(model: model ?? "", msgHeader: header)
        hexdata.updateField(DeviceHexDataField(hexbytes: Data(hexString: "a10122")))
        hexdata.addTimestampField()
        return hexdata
    }

    _ = params
    return nil
}

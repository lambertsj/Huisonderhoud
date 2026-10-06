import Foundation
import Testing
@testable import Huisonderhoud

/// Valideert de dataset tegen docs/onderhoudstaken.schema.json. Een klein stuk JSON
/// Schema (type, required, properties, additionalProperties, items, enum, minimum,
/// maximum, minLength, pattern, uniqueItems, $ref naar $defs), genoeg voor dit schema.
struct SchemaValidatieTests {
    @Test("onderhoudstaken.json voldoet aan het JSON Schema")
    func datasetVoldoet() throws {
        let schemaURL = try #require(Bundle(for: TestAnker.self).url(forResource: "onderhoudstaken.schema", withExtension: "json"))
        let schema = try JSONSerialization.jsonObject(with: Data(contentsOf: schemaURL)) as! [String: Any]
        let appBundle = Bundle(for: HuisonderhoudBundleAnker.self)
        let dataURL = try #require(appBundle.url(forResource: "onderhoudstaken", withExtension: "json"))
        let data = try JSONSerialization.jsonObject(with: Data(contentsOf: dataURL))
        let fouten = Mini.valideer(data, tegen: schema, wortel: schema, pad: "$")
        #expect(fouten.isEmpty, "\(fouten.joined(separator: "\n"))")
    }

    @Test("De validator herkent een fout")
    func validatorWerkt() throws {
        let schemaURL = try #require(Bundle(for: TestAnker.self).url(forResource: "onderhoudstaken.schema", withExtension: "json"))
        let schema = try JSONSerialization.jsonObject(with: Data(contentsOf: schemaURL)) as! [String: Any]
        let kapot: [String: Any] = ["meta": ["versie": "1"], "taken": [["id": "Fout Id", "titel": "", "extra": 1]]]
        #expect(!Mini.valideer(kapot, tegen: schema, wortel: schema, pad: "$").isEmpty)
    }
}

final class TestAnker {}

enum Mini {
    static func valideer(_ waarde: Any, tegen schema: [String: Any], wortel: [String: Any], pad: String) -> [String] {
        var fouten: [String] = []
        if let ref = schema["$ref"] as? String {
            let naam = ref.replacingOccurrences(of: "#/$defs/", with: "")
            let defs = wortel["$defs"] as? [String: Any] ?? [:]
            if let doel = defs[naam] as? [String: Any] {
                return valideer(waarde, tegen: doel, wortel: wortel, pad: pad)
            }
            return ["\(pad): onbekende $ref \(ref)"]
        }
        if let type = schema["type"] {
            let types = (type as? [String]) ?? [type as! String]
            if !types.contains(where: { komtOvereen(waarde, type: $0) }) {
                return ["\(pad): verwacht type \(types), kreeg \(Swift.type(of: waarde))"]
            }
        }
        if let opties = schema["enum"] as? [String], let s = waarde as? String, !opties.contains(s) {
            fouten.append("\(pad): '\(s)' staat niet in de enum")
        }
        if let s = waarde as? String {
            if let min = schema["minLength"] as? Int, s.count < min { fouten.append("\(pad): tekst te kort") }
            if let patroon = schema["pattern"] as? String, s.range(of: patroon, options: .regularExpression) == nil {
                fouten.append("\(pad): '\(s)' past niet op \(patroon)")
            }
        }
        if let n = waarde as? NSNumber, !isBool(n) {
            if let min = schema["minimum"] as? Int, n.intValue < min { fouten.append("\(pad): \(n) is kleiner dan \(min)") }
            if let max = schema["maximum"] as? Int, n.intValue > max { fouten.append("\(pad): \(n) is groter dan \(max)") }
        }
        if let dict = waarde as? [String: Any] {
            for sleutel in schema["required"] as? [String] ?? [] where dict[sleutel] == nil {
                fouten.append("\(pad): '\(sleutel)' ontbreekt")
            }
            let props = schema["properties"] as? [String: Any] ?? [:]
            for (sleutel, kind) in dict {
                if let sub = props[sleutel] as? [String: Any] {
                    fouten += valideer(kind, tegen: sub, wortel: wortel, pad: "\(pad).\(sleutel)")
                } else if schema["additionalProperties"] as? Bool == false {
                    fouten.append("\(pad): onbekend veld '\(sleutel)'")
                }
            }
        }
        if let lijst = waarde as? [Any] {
            if let sub = schema["items"] as? [String: Any] {
                for (i, element) in lijst.enumerated() {
                    fouten += valideer(element, tegen: sub, wortel: wortel, pad: "\(pad)[\(i)]")
                }
            }
            if schema["uniqueItems"] as? Bool == true {
                let beschrijvingen = lijst.map { "\($0)" }
                if Set(beschrijvingen).count != beschrijvingen.count { fouten.append("\(pad): dubbele elementen") }
            }
        }
        return fouten
    }

    /// JSONSerialization geeft 1 en true allebei als NSNumber; alleen CFBoolean is echt een Bool.
    private static func isBool(_ n: NSNumber) -> Bool { CFGetTypeID(n) == CFBooleanGetTypeID() }

    private static func komtOvereen(_ waarde: Any, type: String) -> Bool {
        switch type {
        case "object": return waarde is [String: Any]
        case "array": return waarde is [Any]
        case "string": return waarde is String
        case "null": return waarde is NSNull
        case "integer":
            guard let n = waarde as? NSNumber, !isBool(n) else { return false }
            return n.doubleValue == n.doubleValue.rounded()
        default: return false
        }
    }
}

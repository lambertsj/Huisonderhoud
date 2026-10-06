import Foundation

enum KenmerkGroep: CaseIterable, Hashable {
    case verwarming, dakEnGevel, restVanHetHuis, apparaten

    var titel: String {
        switch self {
        case .verwarming: "Verwarming"
        case .dakEnGevel: "Dak en gevel"
        case .restVanHetHuis: "Rest van het huis"
        case .apparaten: "Apparaten en extra's"
        }
    }
}

/// Eén keuze in de onboarding. Een keuze kan meerdere tags zetten.
struct KenmerkKeuze: Identifiable, Hashable {
    let id: String
    let titel: String
    let groep: KenmerkGroep
    let tags: [String]
}

/// Het huisprofiel bestaat uit tags (strings, geen enum, zodat een veranderde tag nooit crasht).
///
/// Let op: de onboarding is een vereenvoudiging. Een cv-ketel kan bijvoorbeeld ook op
/// stadsverwarming zijn aangesloten, of een tuin hoeft geen regenton te hebben. Daarom
/// zijn de tags later los bewerkbaar op het scherm Huis (`tagTitels`).
enum Kenmerken {
    static let keuzes: [KenmerkKeuze] = [
        KenmerkKeuze(id: "cv-ketel", titel: "Cv-ketel", groep: .verwarming, tags: ["cv_ketel", "gas", "radiatoren"]),
        KenmerkKeuze(id: "warmtepomp", titel: "Warmtepomp", groep: .verwarming, tags: ["warmtepomp", "radiatoren"]),
        KenmerkKeuze(id: "houtkachel", titel: "Houtkachel of open haard", groep: .verwarming, tags: ["houtkachel", "open_haard"]),

        KenmerkKeuze(id: "schuin-dak", titel: "Schuin dak", groep: .dakEnGevel, tags: ["schuin_dak"]),
        KenmerkKeuze(id: "plat-dak", titel: "Plat dak", groep: .dakEnGevel, tags: ["plat_dak"]),
        KenmerkKeuze(id: "houten-kozijnen", titel: "Houten kozijnen", groep: .dakEnGevel, tags: ["houten_kozijnen"]),
        KenmerkKeuze(id: "zonnepanelen", titel: "Zonnepanelen", groep: .dakEnGevel, tags: ["zonnepanelen"]),

        KenmerkKeuze(id: "ventilatie", titel: "Mechanische ventilatie", groep: .restVanHetHuis, tags: ["mechanische_ventilatie", "wtw"]),
        KenmerkKeuze(id: "kruipruimte", titel: "Kruipruimte", groep: .restVanHetHuis, tags: ["kruipruimte"]),
        KenmerkKeuze(id: "tuin", titel: "Tuin", groep: .restVanHetHuis, tags: ["tuin", "buitenkraan", "regenton"]),

        KenmerkKeuze(id: "boiler", titel: "Boiler", groep: .apparaten, tags: ["boiler"]),
        KenmerkKeuze(id: "droger", titel: "Droger", groep: .apparaten, tags: ["droger"]),
        KenmerkKeuze(id: "afzuigkap", titel: "Afzuigkap", groep: .apparaten, tags: ["afzuigkap"]),
        KenmerkKeuze(id: "airco", titel: "Airco", groep: .apparaten, tags: ["airco"]),
        KenmerkKeuze(id: "dakraam", titel: "Dakraam", groep: .apparaten, tags: ["dakraam"]),
        KenmerkKeuze(id: "rolluiken", titel: "Rolluiken", groep: .apparaten, tags: ["rolluiken"]),
    ]

    static func keuzes(in groep: KenmerkGroep) -> [KenmerkKeuze] {
        keuzes.filter { $0.groep == groep }
    }

    /// Alle tags die de onboarding kan zetten.
    static var alleTags: Set<String> {
        Set(tagTitels.keys)
    }

    /// Bereikbaar via de onboarding: de unie van de tags van alle keuzes.
    static var bereikbareTags: Set<String> {
        Set(keuzes.flatMap(\.tags))
    }

    /// Leesbare namen voor losse tags (profiel bewerken op het scherm Huis).
    static let tagTitels: [String: String] = [
        "gas": "Gas",
        "houtkachel": "Houtkachel",
        "open_haard": "Open haard",
        "cv_ketel": "Cv-ketel",
        "radiatoren": "Radiatoren",
        "warmtepomp": "Warmtepomp",
        "boiler": "Boiler",
        "buitenkraan": "Buitenkraan",
        "regenton": "Regenton",
        "schuin_dak": "Schuin dak",
        "plat_dak": "Plat dak",
        "houten_kozijnen": "Houten kozijnen",
        "dakraam": "Dakraam",
        "rolluiken": "Rolluiken",
        "mechanische_ventilatie": "Mechanische ventilatie",
        "wtw": "Warmteterugwinning",
        "afzuigkap": "Afzuigkap",
        "kruipruimte": "Kruipruimte",
        "droger": "Droger",
        "zonnepanelen": "Zonnepanelen",
        "airco": "Airco",
        "tuin": "Tuin",
    ]

    /// Tags bij een selectie van keuzes, zonder dubbelen, in vaste volgorde.
    static func tags(voorKeuzes ids: Set<String>) -> [String] {
        var gezien = Set<String>()
        return keuzes.filter { ids.contains($0.id) }.flatMap(\.tags).filter { gezien.insert($0).inserted }
    }
}

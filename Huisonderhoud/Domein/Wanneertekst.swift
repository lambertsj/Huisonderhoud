import Foundation

/// De tekst bij de statusregel van een rij: "sinds september", "in november".
enum Wanneertekst {
    static func maak(status: TaakStatus, datum: Date?, voorkeursMaanden: [Int], nu: Date, kalender: Calendar = .current) -> String {
        guard let datum else { return "bij aanleiding" }
        let c = kalender.dateComponents([.year, .month], from: datum)
        let cn = kalender.dateComponents([.year], from: nu)
        let maand = Datumopmaak.maandnaam(c.month ?? 1)
        let jaarErbij = c.year != cn.year ? " \(c.year ?? 0)" : ""
        switch status {
        case .telaat:
            return "sinds \(maand)\(jaarErbij)"
        case .nu:
            return Planning.geldigeMaanden(voorkeursMaanden).isEmpty ? "rond \(Datumopmaak.korteDag(datum, kalender: kalender))" : ""
        case .later:
            return "In \(maand)\(jaarErbij)"
        case .gedaan:
            return ""
        }
    }

    /// "Elke maand", "Elk half jaar", "Elk jaar" voor het Boekje.
    static func frequentie(intervalMaanden: Int?) -> String {
        guard let n = intervalMaanden, n > 0 else { return "Bij aanleiding" }
        switch n {
        case 1: return "Elke maand"
        case 12: return "Elk jaar"
        case 6: return "Elk half jaar"
        case 3: return "Elk kwartaal"
        default:
            if n % 12 == 0 { return "Elke \(n / 12) jaar" }
            return "Elke \(n) maanden"
        }
    }
}

import Foundation

struct EersteSchemaItem: Equatable {
    let catalogusID: String
    let volgendeDatum: Date
}

/// Het eerste schema na de onboarding: spreid de start, anders staan er op dag één
/// tientallen taken open.
enum EersteSchema {
    /// Zware taken: interval van 12 maanden of meer én alleen door een vakman.
    static func isZwaar(_ taak: CatalogusTaak) -> Bool {
        (taak.intervalMaanden ?? 0) >= 12 && taak.uitvoering == .vakman
    }

    /// Een kortere maand dan dit aantal dagen resterend telt niet meer als "deze maand".
    static let minimaleRestdagenInHuidigeMaand = 14

    static func zwareTaken(catalogus: Catalogus, kenmerken: [String]) -> [CatalogusTaak] {
        catalogus.taken(voorKenmerken: kenmerken).filter(isZwaar)
    }

    /// - Parameter laatsteKeer: per catalogus-id de datum waarop de gebruiker de zware
    ///   taak voor het laatst liet doen. Ontbreekt een taak, dan is het antwoord "Weet ik niet".
    static func maak(catalogus: Catalogus, kenmerken: [String], laatsteKeer: [String: Date] = [:],
                     nu: Date, planning: Planning) -> [EersteSchemaItem] {
        let kalender = planning.kalender
        let vandaag = kalender.startOfDay(for: nu)
        func dag(_ offset: Int) -> Date { kalender.date(byAdding: .day, value: offset, to: vandaag) ?? vandaag }

        let taken = catalogus.taken(voorKenmerken: kenmerken)
        var datums: [String: Date] = [:]
        var groepen: [Venster: [CatalogusTaak]] = [:]

        for taak in taken {
            let spreidingsdag = Planning.spreidingsdag(voor: taak.id)
            if Self.isZwaar(taak) {
                if let laatste = laatsteKeer[taak.id] {
                    datums[taak.id] = planning.volgendeDatum(na: laatste, intervalMaanden: taak.intervalMaanden,
                                                             voorkeursMaanden: taak.maanden, dagInMaand: spreidingsdag)
                } else {
                    groepen[.weetIkNiet, default: []].append(taak)
                }
                continue
            }
            if !Planning.geldigeMaanden(taak.maanden).isEmpty {
                let maand = kalender.component(.month, from: vandaag)
                let restdagen = (kalender.range(of: .day, in: .month, for: vandaag)?.count ?? 30)
                    - kalender.component(.day, from: vandaag)
                if Planning.geldigeMaanden(taak.maanden).contains(maand), restdagen >= minimaleRestdagenInHuidigeMaand {
                    groepen[.dezeMaand, default: []].append(taak)
                } else {
                    datums[taak.id] = planning.eersteDatumInVolgendeVoorkeursmaand(
                        na: vandaag, maanden: taak.maanden, dagInMaand: spreidingsdag)
                }
            } else if let interval = taak.intervalMaanden, interval <= 3 {
                groepen[.kortInterval, default: []].append(taak)
            } else {
                groepen[.overig, default: []].append(taak)
            }
        }

        for (venster, leden) in groepen {
            let (van, tot): (Int, Int)
            switch venster {
            case .kortInterval: (van, tot) = (7, 28)
            case .overig: (van, tot) = (30, 90)
            case .weetIkNiet: (van, tot) = (14, 90)
            case .dezeMaand:
                let eind = kalender.range(of: .day, in: .month, for: vandaag)?.count ?? 30
                (van, tot) = (7, max(7, eind - kalender.component(.day, from: vandaag)))
            }
            for (i, taak) in leden.enumerated() {
                let offset = leden.count == 1 ? (van + tot) / 2 : van + Int((Double(i) * Double(tot - van) / Double(leden.count - 1)).rounded())
                datums[taak.id] = dag(offset)
            }
        }

        return taken.compactMap { taak in
            datums[taak.id].map { EersteSchemaItem(catalogusID: taak.id, volgendeDatum: $0) }
        }
    }

    private enum Venster: Hashable {
        case dezeMaand, kortInterval, overig, weetIkNiet
    }
}

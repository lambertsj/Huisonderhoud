import Foundation

/// Alles wat in het pdf-dossier komt, als losse waarden (geen SwiftData), zodat het
/// renderen buiten de hoofdthread kan en testbaar blijft.
struct DossierInhoud: Sendable {
    struct ApparaatRegel: Sendable {
        var soort: String
        var merk: String
        var model: String
        var serienummer: String
        var aangeschaft: Date?
        var garantieTot: Date?
        var installateur: String
    }

    struct Regel: Sendable {
        var datum: Date
        var titel: String
        var uitvoerder: Uitvoerder
        var uitvoerderNaam: String
        var notitie: String
        /// Kleine JPEG's (thumbnails), maximaal `maximaalAantalFotos` per regel.
        var fotos: [Data]
    }

    struct Jaar: Sendable {
        var jaar: Int
        var regels: [Regel]
    }

    static let maximaalAantalFotos = 3
    static let thumbnailZijde = 320

    var woningnaam: String
    var bouwjaar: Int?
    var woningtype: String
    var datum: Date
    var apparaten: [ApparaatRegel]
    /// Nieuwste jaar eerst, binnen een jaar de nieuwste regel eerst.
    var jaren: [Jaar]
    var kalender: Calendar

    var aantalRegels: Int { jaren.reduce(0) { $0 + $1.regels.count } }

    @MainActor
    static func maak(woning: Woning, datum: Date = Date(), kalender: Calendar = .current) -> DossierInhoud {
        let apparaten = woning.alleApparaten
            .sorted { ($0.soort, $0.merk) < ($1.soort, $1.merk) }
            .map {
                ApparaatRegel(soort: $0.soort, merk: $0.merk, model: $0.model, serienummer: $0.serienummer,
                              aangeschaft: $0.aangeschaftOp, garantieTot: $0.garantieTot,
                              installateur: $0.installateurNaam ?? "")
            }
        let regels = woning.alleUitvoeringen.sorted { $0.datum > $1.datum }.map { u -> (Int, Regel) in
            let fotos = u.alleBijlagen
                .filter { $0.soort == .foto }
                .sorted { $0.aangemaakt < $1.aangemaakt }
                .prefix(maximaalAantalFotos)
                .compactMap { $0.data.flatMap { Fotoverkleiner.verklein($0, maximaleZijde: thumbnailZijde, kwaliteit: 0.7) } }
            let regel = Regel(datum: u.datum, titel: u.titelSnapshot, uitvoerder: u.uitvoerder,
                              uitvoerderNaam: u.uitvoerderNaam ?? "", notitie: u.notitie, fotos: Array(fotos))
            return (kalender.component(.year, from: u.datum), regel)
        }
        let perJaar = Dictionary(grouping: regels, by: \.0)
        let jaren = perJaar.keys.sorted(by: >).map { Jaar(jaar: $0, regels: perJaar[$0]!.map(\.1)) }
        return DossierInhoud(woningnaam: woning.naam, bouwjaar: woning.bouwjaar, woningtype: woning.woningtype,
                             datum: datum, apparaten: apparaten, jaren: jaren, kalender: kalender)
    }
}

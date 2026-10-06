import Foundation

/// Wat een taak laat zien, uit de catalogus of (bij eigen taken) uit de taak zelf.
struct TaakInhoud: Equatable {
    var titel: String
    var uitleg: String
    var categorie: String
    var waarschuwing: String?
    var uitvoering: UitvoeringSoort
    var duurMin: Int?
    var intervalMaanden: Int?
    var voorkeursMaanden: [Int]
    /// True bij eigen taken en bij taken die uit de catalogus zijn verdwenen.
    var isEigen: Bool
}

extension Taak {
    func inhoud(in catalogus: Catalogus) -> TaakInhoud {
        if let id = catalogusID, let cat = catalogus.taak(met: id) {
            return TaakInhoud(
                titel: cat.titel, uitleg: cat.uitleg, categorie: cat.categorie,
                waarschuwing: cat.waarschuwing, uitvoering: cat.uitvoering, duurMin: cat.duurMin,
                intervalMaanden: intervalMaanden ?? cat.intervalMaanden,
                voorkeursMaanden: voorkeursMaanden.isEmpty ? cat.maanden : voorkeursMaanden,
                isEigen: false)
        }
        return TaakInhoud(
            titel: eigenTitel, uitleg: eigenUitleg, categorie: eigenCategorie,
            waarschuwing: eigenWaarschuwing, uitvoering: UitvoeringSoort(rawValue: eigenUitvoering) ?? .zelf,
            duurMin: eigenDuurMin, intervalMaanden: intervalMaanden, voorkeursMaanden: voorkeursMaanden,
            isEigen: true)
    }
}

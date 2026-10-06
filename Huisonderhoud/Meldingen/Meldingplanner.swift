import Foundation

struct MeldingKandidaat: Equatable {
    let id: UUID
    let titel: String
    let volgendeDatum: Date?
    let isActief: Bool
    let herinneringAan: Bool
}

struct GeplandeMelding: Equatable {
    let identifier: String
    let titel: String
    /// De datum om 09:00 lokale tijd.
    let moment: Date
}

/// Bepaalt welke lokale meldingen er gepland worden. iOS staat maximaal 64 geplande
/// lokale meldingen toe; we plannen alleen de eerstvolgende ongeveer 50.
enum Meldingplanner {
    static let maximum = 50
    static let uur = 9
    static let identifierVoorvoegsel = "taak-"

    static func plan(_ kandidaten: [MeldingKandidaat], nu: Date, kalender: Calendar = .current,
                     maximum: Int = Meldingplanner.maximum) -> [GeplandeMelding] {
        let gepland: [GeplandeMelding] = kandidaten.compactMap { k in
            guard k.isActief, k.herinneringAan, let datum = k.volgendeDatum else { return nil }
            guard let moment = kalender.date(bySettingHour: uur, minute: 0, second: 0, of: datum), moment > nu else { return nil }
            return GeplandeMelding(identifier: identifierVoorvoegsel + k.id.uuidString, titel: k.titel, moment: moment)
        }
        return Array(gepland.sorted { ($0.moment, $0.identifier) < ($1.moment, $1.identifier) }.prefix(maximum))
    }
}

import Foundation

/// Status van een taak op het scherm Nu en in het Schema.
enum TaakStatus: String, Codable, CaseIterable {
    case telaat, nu, later, gedaan
}

/// Wie een catalogustaak mag uitvoeren (veld `uitvoering` in de dataset).
enum UitvoeringSoort: String, Codable, CaseIterable {
    case zelf, vakman
    case zelfOfVakman = "zelf_of_vakman"

    var label: String {
        switch self {
        case .zelf: "Zelf"
        case .vakman: "Vakman"
        case .zelfOfVakman: "Zelf of vakman"
        }
    }
}

/// Wie een klus daadwerkelijk heeft gedaan (logboek).
enum Uitvoerder: String, Codable, CaseIterable {
    case zelf, vakman, anders

    var label: String {
        switch self {
        case .zelf: "Zelf"
        case .vakman: "Vakman"
        case .anders: "Anders"
        }
    }
}

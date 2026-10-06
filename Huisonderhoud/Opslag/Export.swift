import CoreTransferable
import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Eén JSON-bestand met alle gebruikersdata. Geen account en geen backend betekent dat de
/// gebruiker zelf eigenaar van zijn data is. Relaties lopen via de UUID's.
struct Export: Codable, Equatable {
    static let huidigeVersie = 1

    var versie: Int
    var geexporteerdOp: Date
    var catalogusVersie: String
    var woningen: [WoningDTO]
    var taken: [TaakDTO]
    var apparaten: [ApparaatDTO]
    var uitvoeringen: [UitvoeringDTO]
    /// Foto's zijn al verkleind (maximaal 2000 px, JPEG 0,8); `Data` wordt als base64 geschreven.
    var bijlagen: [BijlageDTO]

    struct WoningDTO: Codable, Equatable {
        var id: UUID
        var naam: String
        var bouwjaar: Int?
        var woningtype: String
        var kenmerken: [String]
        var eigenaarSinds: Date?
        var catalogusVersie: String
        var negeerVoorstellen: [String]
    }

    struct TaakDTO: Codable, Equatable {
        var id: UUID
        var woningID: UUID?
        var apparaatID: UUID?
        var catalogusID: String?
        var eigenTitel: String
        var eigenUitleg: String
        var eigenCategorie: String
        var eigenWaarschuwing: String?
        var eigenUitvoering: String
        var eigenDuurMin: Int?
        var intervalMaanden: Int?
        var voorkeursMaanden: [Int]
        var volgendeDatum: Date?
        var isActief: Bool
        var herinneringAan: Bool
    }

    struct ApparaatDTO: Codable, Equatable {
        var id: UUID
        var woningID: UUID?
        var soort: String
        var merk: String
        var model: String
        var serienummer: String
        var aangeschaftOp: Date?
        var garantieTot: Date?
        var installateurNaam: String?
        var notitie: String
    }

    struct UitvoeringDTO: Codable, Equatable {
        var id: UUID
        var woningID: UUID?
        var taakID: UUID?
        var datum: Date
        var titelSnapshot: String
        var categorieSnapshot: String
        var uitvoerder: String
        var uitvoerderNaam: String?
        var notitie: String
        var kostenCenten: Int?
    }

    struct BijlageDTO: Codable, Equatable {
        var id: UUID
        var woningID: UUID?
        var apparaatID: UUID?
        var uitvoeringID: UUID?
        var soort: String
        var titel: String?
        var aangemaakt: Date
        var data: Data?
    }

    // MARK: Maken

    /// Datums gaan als ISO 8601 op de seconde nauwkeurig het bestand in; zo is een rondreis exact.
    private static func sec(_ datum: Date) -> Date { Date(timeIntervalSince1970: datum.timeIntervalSince1970.rounded(.down)) }
    private static func sec(_ datum: Date?) -> Date? { datum.map(sec) }

    static func maak(context: ModelContext, nu: Date = Date(), catalogusVersie: String = "") throws -> Export {
        func sorteer<T>(_ lijst: [T], op sleutel: (T) -> String) -> [T] { lijst.sorted { sleutel($0) < sleutel($1) } }
        let woningen = sorteer(try context.fetch(FetchDescriptor<Woning>()), op: { $0.id.uuidString })
        let taken = sorteer(try context.fetch(FetchDescriptor<Taak>()), op: { $0.id.uuidString })
        let apparaten = sorteer(try context.fetch(FetchDescriptor<Apparaat>()), op: { $0.id.uuidString })
        let uitvoeringen = sorteer(try context.fetch(FetchDescriptor<Uitvoering>()), op: { $0.id.uuidString })
        let bijlagen = sorteer(try context.fetch(FetchDescriptor<Bijlage>()), op: { $0.id.uuidString })

        return Export(
            versie: huidigeVersie, geexporteerdOp: sec(nu), catalogusVersie: catalogusVersie,
            woningen: woningen.map {
                WoningDTO(id: $0.id, naam: $0.naam, bouwjaar: $0.bouwjaar, woningtype: $0.woningtype, kenmerken: $0.kenmerken,
                          eigenaarSinds: sec($0.eigenaarSinds), catalogusVersie: $0.catalogusVersie, negeerVoorstellen: $0.negeerVoorstellen)
            },
            taken: taken.map {
                TaakDTO(id: $0.id, woningID: $0.woning?.id, apparaatID: $0.apparaat?.id, catalogusID: $0.catalogusID,
                        eigenTitel: $0.eigenTitel, eigenUitleg: $0.eigenUitleg, eigenCategorie: $0.eigenCategorie,
                        eigenWaarschuwing: $0.eigenWaarschuwing, eigenUitvoering: $0.eigenUitvoering, eigenDuurMin: $0.eigenDuurMin,
                        intervalMaanden: $0.intervalMaanden, voorkeursMaanden: $0.voorkeursMaanden, volgendeDatum: sec($0.volgendeDatum),
                        isActief: $0.isActief, herinneringAan: $0.herinneringAan)
            },
            apparaten: apparaten.map {
                ApparaatDTO(id: $0.id, woningID: $0.woning?.id, soort: $0.soort, merk: $0.merk, model: $0.model,
                            serienummer: $0.serienummer, aangeschaftOp: sec($0.aangeschaftOp), garantieTot: sec($0.garantieTot),
                            installateurNaam: $0.installateurNaam, notitie: $0.notitie)
            },
            uitvoeringen: uitvoeringen.map {
                UitvoeringDTO(id: $0.id, woningID: $0.woning?.id, taakID: $0.taak?.id, datum: sec($0.datum),
                              titelSnapshot: $0.titelSnapshot, categorieSnapshot: $0.categorieSnapshot, uitvoerder: $0.uitvoerderRaw,
                              uitvoerderNaam: $0.uitvoerderNaam, notitie: $0.notitie, kostenCenten: $0.kostenCenten)
            },
            bijlagen: bijlagen.map {
                BijlageDTO(id: $0.id, woningID: $0.woning?.id, apparaatID: $0.apparaat?.id, uitvoeringID: $0.uitvoering?.id,
                           soort: $0.soortRaw, titel: $0.titel, aangemaakt: sec($0.aangemaakt), data: $0.data)
            })
    }

    // MARK: Coderen

    func data() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(self)
    }

    enum Fout: Error, Equatable, LocalizedError {
        case onleesbaar
        case nieuwereVersie(Int)

        var errorDescription: String? {
            switch self {
            case .onleesbaar: "Dit bestand is geen geldige export van Huisonderhoud."
            case .nieuwereVersie: "Dit bestand komt uit een nieuwere versie van de app. Werk de app bij en probeer het opnieuw."
            }
        }
    }

    static func lees(_ data: Data) throws -> Export {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // Eerst alleen de versie, zodat een nieuwere indeling een duidelijke melding geeft.
        struct Kop: Decodable { var versie: Int }
        guard let kop = try? decoder.decode(Kop.self, from: data) else { throw Fout.onleesbaar }
        guard kop.versie <= huidigeVersie else { throw Fout.nieuwereVersie(kop.versie) }
        guard let export = try? decoder.decode(Export.self, from: data) else { throw Fout.onleesbaar }
        return export
    }
}

/// Het exportbestand als deelbaar item. Maakt de export pas bij het delen, met een eigen context.
struct ExportBestand: Transferable {
    let container: ModelContainer
    let catalogusVersie: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { bestand in
            let context = ModelContext(bestand.container)
            let nu = Date()
            let export = try Export.maak(context: context, nu: nu, catalogusVersie: bestand.catalogusVersie)
            let f = DateFormatter()
            f.locale = Locale(identifier: "nl_NL")
            f.dateFormat = "yyyy-MM-dd"
            let map = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: map, withIntermediateDirectories: true)
            let url = map.appendingPathComponent("Huisonderhoud gegevens \(f.string(from: nu)).json")
            try export.data().write(to: url)
            return SentTransferredFile(url)
        }
    }
}

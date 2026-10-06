import Foundation
import SwiftData

// Alle modellen zijn CloudKit-compatibel, ook al staat sync in v1 uit:
// elke property heeft een default of is optional, relaties zijn optional,
// en er is geen `@Attribute(.unique)`. Elke entiteit heeft een `id: UUID`
// voor export en import.

@Model
final class Woning {
    var id: UUID = UUID()
    var naam: String = ""
    var bouwjaar: Int?
    var woningtype: String = ""
    /// Tags uit het huisprofiel, als strings.
    var kenmerken: [String] = []
    var eigenaarSinds: Date?
    var catalogusVersie: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Taak.woning) var taken: [Taak]? = []
    @Relationship(deleteRule: .cascade, inverse: \Apparaat.woning) var apparaten: [Apparaat]? = []
    @Relationship(deleteRule: .cascade, inverse: \Uitvoering.woning) var uitvoeringen: [Uitvoering]? = []
    @Relationship(deleteRule: .cascade, inverse: \Bijlage.woning) var bijlagen: [Bijlage]? = []

    init(naam: String = "Mijn huis", bouwjaar: Int? = nil, woningtype: String = "",
         kenmerken: [String] = [], eigenaarSinds: Date? = nil, catalogusVersie: String = "") {
        self.naam = naam
        self.bouwjaar = bouwjaar
        self.woningtype = woningtype
        self.kenmerken = kenmerken
        self.eigenaarSinds = eigenaarSinds
        self.catalogusVersie = catalogusVersie
    }

    var alleTaken: [Taak] { taken ?? [] }
    var alleApparaten: [Apparaat] { apparaten ?? [] }
    var alleUitvoeringen: [Uitvoering] { uitvoeringen ?? [] }
}

/// De persoonlijke planning van één catalogustaak voor één woning (of een eigen taak).
///
/// De `eigen…`-velden zijn bij eigen taken de inhoud zelf. Bij een catalogustaak bewaren
/// ze de laatst bekende tekst, zodat de taak leesbaar blijft als hij uit een nieuwe
/// catalogus verdwijnt (dan wordt het een eigen taak).
@Model
final class Taak {
    var id: UUID = UUID()
    /// nil = eigen taak. Geen echte relatie met de catalogus.
    var catalogusID: String?
    var eigenTitel: String = ""
    var eigenUitleg: String = ""
    var eigenCategorie: String = ""
    var eigenWaarschuwing: String?
    var eigenUitvoering: String = UitvoeringSoort.zelf.rawValue
    var eigenDuurMin: Int?
    var intervalMaanden: Int?
    /// Voor eigen taken, of als override van de catalogus.
    var voorkeursMaanden: [Int] = []
    /// Opgeslagen, niet steeds uitgerekend.
    var volgendeDatum: Date?
    var isActief: Bool = true
    var herinneringAan: Bool = true

    var woning: Woning?
    var apparaat: Apparaat?
    @Relationship(deleteRule: .nullify, inverse: \Uitvoering.taak) var uitvoeringen: [Uitvoering]? = []

    init(catalogusID: String? = nil, eigenTitel: String = "", eigenUitleg: String = "",
         eigenCategorie: String = "", intervalMaanden: Int? = nil, voorkeursMaanden: [Int] = [],
         volgendeDatum: Date? = nil, woning: Woning? = nil) {
        self.catalogusID = catalogusID
        self.eigenTitel = eigenTitel
        self.eigenUitleg = eigenUitleg
        self.eigenCategorie = eigenCategorie
        self.intervalMaanden = intervalMaanden
        self.voorkeursMaanden = voorkeursMaanden
        self.volgendeDatum = volgendeDatum
        self.woning = woning
    }

    /// Een taak uit de catalogus, met de laatst bekende tekst als terugval.
    convenience init(catalogus: CatalogusTaak, volgendeDatum: Date?, woning: Woning?) {
        self.init(catalogusID: catalogus.id, eigenTitel: catalogus.titel, eigenUitleg: catalogus.uitleg,
                  eigenCategorie: catalogus.categorie, volgendeDatum: volgendeDatum, woning: woning)
        eigenWaarschuwing = catalogus.waarschuwing
        eigenUitvoering = catalogus.uitvoering.rawValue
        eigenDuurMin = catalogus.duurMin
    }

    var alleUitvoeringen: [Uitvoering] { uitvoeringen ?? [] }
    var laatsteUitvoering: Uitvoering? { alleUitvoeringen.max(by: { $0.datum < $1.datum }) }
}

/// Het logboek. Snapshots houden een regel leesbaar als de taak verdwijnt.
@Model
final class Uitvoering {
    var id: UUID = UUID()
    var datum: Date = Date()
    var titelSnapshot: String = ""
    var categorieSnapshot: String = ""
    var uitvoerderRaw: String = Uitvoerder.zelf.rawValue
    var uitvoerderNaam: String?
    var notitie: String = ""
    /// Nog geen UI in v1.
    var kostenCenten: Int?

    var taak: Taak?
    var woning: Woning?
    @Relationship(deleteRule: .cascade, inverse: \Bijlage.uitvoering) var bijlagen: [Bijlage]? = []

    init(datum: Date = Date(), titelSnapshot: String = "", categorieSnapshot: String = "",
         uitvoerder: Uitvoerder = .zelf, uitvoerderNaam: String? = nil, notitie: String = "",
         taak: Taak? = nil, woning: Woning? = nil) {
        self.datum = datum
        self.titelSnapshot = titelSnapshot
        self.categorieSnapshot = categorieSnapshot
        self.uitvoerderRaw = uitvoerder.rawValue
        self.uitvoerderNaam = uitvoerderNaam
        self.notitie = notitie
        self.taak = taak
        self.woning = woning
    }

    var uitvoerder: Uitvoerder {
        get { Uitvoerder(rawValue: uitvoerderRaw) ?? .anders }
        set { uitvoerderRaw = newValue.rawValue }
    }

    var alleBijlagen: [Bijlage] { bijlagen ?? [] }
}

@Model
final class Apparaat {
    var id: UUID = UUID()
    var soort: String = ""
    var merk: String = ""
    var model: String = ""
    var serienummer: String = ""
    var aangeschaftOp: Date?
    var garantieTot: Date?
    var installateurNaam: String?
    var notitie: String = ""

    var woning: Woning?
    @Relationship(deleteRule: .nullify, inverse: \Taak.apparaat) var taken: [Taak]? = []
    @Relationship(deleteRule: .cascade, inverse: \Bijlage.apparaat) var bijlagen: [Bijlage]? = []

    init(soort: String = "", merk: String = "", model: String = "", serienummer: String = "",
         aangeschaftOp: Date? = nil, garantieTot: Date? = nil, installateurNaam: String? = nil,
         notitie: String = "", woning: Woning? = nil) {
        self.soort = soort
        self.merk = merk
        self.model = model
        self.serienummer = serienummer
        self.aangeschaftOp = aangeschaftOp
        self.garantieTot = garantieTot
        self.installateurNaam = installateurNaam
        self.notitie = notitie
        self.woning = woning
    }

    var alleBijlagen: [Bijlage] { bijlagen ?? [] }
}

enum BijlageSoort: String, Codable {
    case foto, pdf
}

@Model
final class Bijlage {
    var id: UUID = UUID()
    var soortRaw: String = BijlageSoort.foto.rawValue
    var titel: String?
    @Attribute(.externalStorage) var data: Data?
    var aangemaakt: Date = Date()

    var uitvoering: Uitvoering?
    var apparaat: Apparaat?
    var woning: Woning?

    init(soort: BijlageSoort = .foto, titel: String? = nil, data: Data? = nil, aangemaakt: Date = Date()) {
        self.soortRaw = soort.rawValue
        self.titel = titel
        self.data = data
        self.aangemaakt = aangemaakt
    }

    var soort: BijlageSoort {
        get { BijlageSoort(rawValue: soortRaw) ?? .foto }
        set { soortRaw = newValue.rawValue }
    }

    static let schema: [any PersistentModel.Type] = [Woning.self, Taak.self, Uitvoering.self, Apparaat.self, Bijlage.self]
}

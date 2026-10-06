import Foundation

/// Eén taak uit `onderhoudstaken.json`. Read-only; de dataset zit als resource in de app.
struct CatalogusTaak: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let titel: String
    let categorie: String
    let intervalMaanden: Int?
    let maanden: [Int]
    let uitvoering: UitvoeringSoort
    let duurMin: Int?
    /// Tags uit het huisprofiel. Any-of: één match is genoeg. Leeg = voor elk huis.
    let voorwaarde: [String]
    let uitleg: String
    let waarschuwing: String?

    enum CodingKeys: String, CodingKey {
        case id, titel, categorie, maanden, uitvoering, voorwaarde, uitleg, waarschuwing
        case intervalMaanden = "interval_maanden"
        case duurMin = "duur_min"
    }

    init(id: String, titel: String, categorie: String, intervalMaanden: Int?, maanden: [Int] = [],
         uitvoering: UitvoeringSoort, duurMin: Int? = nil, voorwaarde: [String] = [],
         uitleg: String, waarschuwing: String? = nil) {
        self.id = id
        self.titel = titel
        self.categorie = categorie
        self.intervalMaanden = intervalMaanden
        self.maanden = maanden
        self.uitvoering = uitvoering
        self.duurMin = duurMin
        self.voorwaarde = voorwaarde
        self.uitleg = uitleg
        self.waarschuwing = waarschuwing
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        titel = try c.decode(String.self, forKey: .titel)
        categorie = try c.decode(String.self, forKey: .categorie)
        intervalMaanden = try c.decodeIfPresent(Int.self, forKey: .intervalMaanden)
        maanden = try c.decodeIfPresent([Int].self, forKey: .maanden) ?? []
        uitvoering = try c.decode(UitvoeringSoort.self, forKey: .uitvoering)
        duurMin = try c.decodeIfPresent(Int.self, forKey: .duurMin)
        voorwaarde = try c.decodeIfPresent([String].self, forKey: .voorwaarde) ?? []
        uitleg = try c.decode(String.self, forKey: .uitleg)
        waarschuwing = try c.decodeIfPresent(String.self, forKey: .waarschuwing)
    }
}

struct CatalogusMeta: Codable, Hashable, Sendable {
    let versie: String
}

/// De gebundelde dataset. Geen SwiftData: een correctie komt via een app-update.
struct Catalogus: Codable, Sendable {
    let meta: CatalogusMeta
    let taken: [CatalogusTaak]

    var versie: String { meta.versie }

    /// Volgorde van de categorieën op het scherm Schema.
    static let categorieVolgorde = [
        "Veiligheid", "Verwarming", "Water", "Dak en gevel", "Ramen en deuren", "Ventilatie",
        "Vocht", "Badkamer en keuken", "Apparaten", "Energie", "Tuin", "Seizoen",
    ]

    func taak(met id: String) -> CatalogusTaak? {
        index[id]
    }

    private var index: [String: CatalogusTaak] {
        Dictionary(taken.map { ($0.id, $0) }, uniquingKeysWith: { eerste, _ in eerste })
    }

    /// Taken die bij een woning met deze kenmerken horen (any-of; leeg = altijd).
    func taken(voorKenmerken kenmerken: [String]) -> [CatalogusTaak] {
        let set = Set(kenmerken)
        return taken.filter { $0.voorwaarde.isEmpty || !set.isDisjoint(with: $0.voorwaarde) }
    }

    // MARK: Laden

    enum Fout: Error, Equatable {
        case bestandOntbreekt
        case ongeldig(String)
    }

    static func decodeer(_ data: Data) throws -> Catalogus {
        do {
            return try JSONDecoder().decode(Catalogus.self, from: data)
        } catch {
            throw Fout.ongeldig(String(describing: error))
        }
    }

    static func gebundeld(bundle: Bundle = Bundle(for: HuisonderhoudBundleAnker.self)) throws -> Catalogus {
        guard let url = bundle.url(forResource: "onderhoudstaken", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { throw Fout.bestandOntbreekt }
        return try decodeer(data)
    }

    // MARK: Validatie

    /// Lege lijst = alles in orde. Elke melding is één regel om in een test of log te tonen.
    func valideer() -> [String] {
        var problemen: [String] = []
        var gezien = Set<String>()
        let geldigeTags = Kenmerken.alleTags
        for taak in taken {
            if !gezien.insert(taak.id).inserted { problemen.append("\(taak.id): id komt vaker voor") }
            if taak.id.trimmingCharacters(in: .whitespaces).isEmpty { problemen.append("leeg id bij '\(taak.titel)'") }
            if taak.titel.trimmingCharacters(in: .whitespaces).isEmpty { problemen.append("\(taak.id): titel is leeg") }
            if taak.uitleg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { problemen.append("\(taak.id): uitleg is leeg") }
            if !Self.categorieVolgorde.contains(taak.categorie) { problemen.append("\(taak.id): onbekende categorie '\(taak.categorie)'") }
            if let interval = taak.intervalMaanden, interval <= 0 { problemen.append("\(taak.id): interval_maanden moet positief zijn") }
            if let duur = taak.duurMin, duur <= 0 { problemen.append("\(taak.id): duur_min moet positief zijn") }
            if let fout = taak.maanden.first(where: { !(1...12).contains($0) }) { problemen.append("\(taak.id): maand \(fout) valt buiten 1 tot 12") }
            for tag in taak.voorwaarde where !geldigeTags.contains(tag) {
                problemen.append("\(taak.id): onbekende tag '\(tag)'")
            }
            if let w = taak.waarschuwing, w.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                problemen.append("\(taak.id): waarschuwing is leeg (laat het veld dan weg)")
            }
        }
        if meta.versie.isEmpty { problemen.append("meta.versie ontbreekt") }
        return problemen
    }
}

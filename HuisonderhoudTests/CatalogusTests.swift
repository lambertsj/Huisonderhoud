import Foundation
import Testing
@testable import Huisonderhoud

struct CatalogusTests {
    @Test("De gebundelde catalogus laadt")
    func laadt() throws {
        let catalogus = try gebundeldeCatalogus()
        #expect(!catalogus.taken.isEmpty)
        #expect(!catalogus.versie.isEmpty)
    }

    @Test("De gebundelde catalogus is geldig")
    func geldig() throws {
        let problemen = try gebundeldeCatalogus().valideer()
        #expect(problemen.isEmpty, "\(problemen.joined(separator: "\n"))")
    }

    @Test("Ids zijn uniek")
    func idsUniek() throws {
        let ids = try gebundeldeCatalogus().taken.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Interval positief of null, maanden 1 tot 12, uitleg niet leeg")
    func velden() throws {
        for taak in try gebundeldeCatalogus().taken {
            if let i = taak.intervalMaanden { #expect(i > 0, "\(taak.id)") }
            #expect(taak.maanden.allSatisfy { (1...12).contains($0) }, "\(taak.id)")
            #expect(!taak.uitleg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(taak.id)")
        }
    }

    @Test("Elke tag in de dataset is bereikbaar via de onboarding")
    func tagsBereikbaar() throws {
        let gebruikt = Set(try gebundeldeCatalogus().taken.flatMap(\.voorwaarde))
        let bereikbaar = Kenmerken.bereikbareTags
        #expect(gebruikt.subtracting(bereikbaar).isEmpty, "Niet bereikbaar: \(gebruikt.subtracting(bereikbaar).sorted())")
    }

    @Test("Elke tag die de onboarding zet heeft een leesbare naam")
    func tagTitels() {
        #expect(Kenmerken.bereikbareTags.subtracting(Kenmerken.alleTags).isEmpty)
    }

    @Test("Voorwaarde is any-of; leeg betekent altijd")
    func anyOf() throws {
        let catalogus = try gebundeldeCatalogus()
        let leeg = catalogus.taken(voorKenmerken: [])
        #expect(leeg.allSatisfy { $0.voorwaarde.isEmpty })
        let metHout = catalogus.taken(voorKenmerken: ["open_haard"])
        // veiligheid-co-melder: gas, houtkachel of open_haard. Eén match is genoeg.
        #expect(metHout.contains { $0.id == "veiligheid-co-melder" })
        #expect(!leeg.contains { $0.id == "veiligheid-co-melder" })
    }

    @Test("Een ongeldige catalogus wordt herkend")
    func ongeldig() {
        let kapot = Catalogus(meta: CatalogusMeta(versie: "x"), taken: [
            CatalogusTaak(id: "a", titel: "A", categorie: "Tuin", intervalMaanden: 0, maanden: [13], uitvoering: .zelf, voorwaarde: ["bestaat_niet"], uitleg: " "),
            CatalogusTaak(id: "a", titel: "B", categorie: "Onbekend", intervalMaanden: 1, uitvoering: .zelf, uitleg: "ok"),
        ])
        let problemen = kapot.valideer()
        #expect(problemen.count >= 6, "\(problemen)")
    }

    @Test("Kapotte JSON geeft een fout, geen crash")
    func kapotteJSON() {
        #expect(throws: Catalogus.Fout.self) { try Catalogus.decodeer(Data("{}".utf8)) }
    }

    @Test("Zware taken zijn de vakmantaken met interval van 12 maanden of meer")
    func zwareTaken() throws {
        let zwaar = try gebundeldeCatalogus().taken.filter(EersteSchema.isZwaar).map(\.id)
        #expect(zwaar.contains("verwarming-cv-onderhoud"))
        #expect(zwaar.contains("water-boiler-ontkalken"))
        #expect(!zwaar.contains("gevel-schilderen"))
    }
}

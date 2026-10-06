import Foundation
import SwiftData
import Testing
@testable import Huisonderhoud

@MainActor
struct HuisdienstTests {
    private func opzet() throws -> (Huisdienst, ModelContext) {
        let container = try ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return (Huisdienst(catalogus: try gebundeldeCatalogus(), planning: Testtijd.planning), ModelContext(container))
    }

    @Test("Het eerste schema maakt een woning met één taak per passende catalogustaak")
    func maakSchema() throws {
        let (dienst, context) = try opzet()
        let tags = Kenmerken.tags(voorKeuzes: ["cv-ketel", "tuin"])
        let woning = dienst.maakSchema(kenmerken: tags, context: context, nu: Testtijd.datum(2026, 10, 6))
        let verwacht = dienst.catalogus.taken(voorKenmerken: tags).count
        #expect(woning.alleTaken.count == verwacht)
        #expect(woning.catalogusVersie == dienst.catalogus.versie)
        #expect(woning.alleTaken.allSatisfy { $0.volgendeDatum != nil && $0.isActief && $0.catalogusID != nil })
        #expect(try context.fetch(FetchDescriptor<Woning>()).count == 1)
    }

    @Test("Zonder kenmerken alleen de taken voor elk huis")
    func zonderKenmerken() throws {
        let (dienst, context) = try opzet()
        let woning = dienst.maakSchema(kenmerken: [], context: context, nu: Testtijd.datum(2026, 10, 6))
        #expect(woning.alleTaken.count == dienst.catalogus.taken(voorKenmerken: []).count)
        #expect(dienst.zwareTaken(voor: woning).isEmpty)
    }

    @Test("Een opgegeven laatste keer verplaatst alleen die zware taak")
    func laatsteKeer() throws {
        let (dienst, context) = try opzet()
        let nu = Testtijd.datum(2026, 10, 6)
        let woning = dienst.maakSchema(kenmerken: Kenmerken.tags(voorKeuzes: ["boiler", "cv-ketel"]), context: context, nu: nu)
        let voor = Dictionary(uniqueKeysWithValues: woning.alleTaken.map { ($0.catalogusID!, $0.volgendeDatum) })
        dienst.pasLaatsteKeerToe(["water-boiler-ontkalken": Testtijd.datum(2025, 6, 1)], woning: woning, context: context, nu: nu)
        for taak in woning.alleTaken {
            if taak.catalogusID == "water-boiler-ontkalken" {
                #expect(Testtijd.onderdelen(taak.volgendeDatum!) == (2029, 6, 1))
            } else {
                #expect(taak.volgendeDatum == voor[taak.catalogusID!]!, "\(taak.catalogusID!) is verschoven")
            }
        }
    }
}

struct WanneertekstTests {
    let k = Testtijd.kalender

    @Test("Te laat, nu en later")
    func teksten() {
        let nu = Testtijd.datum(2026, 10, 15)
        #expect(Wanneertekst.maak(status: .telaat, datum: Testtijd.datum(2026, 9, 1), voorkeursMaanden: [9], nu: nu, kalender: k) == "sinds september")
        #expect(Wanneertekst.maak(status: .telaat, datum: Testtijd.datum(2025, 12, 1), voorkeursMaanden: [], nu: nu, kalender: k) == "sinds december 2025")
        #expect(Wanneertekst.maak(status: .nu, datum: Testtijd.datum(2026, 10, 20), voorkeursMaanden: [], nu: nu, kalender: k) == "rond 20 okt")
        #expect(Wanneertekst.maak(status: .nu, datum: Testtijd.datum(2026, 10, 1), voorkeursMaanden: [10], nu: nu, kalender: k) == "")
        #expect(Wanneertekst.maak(status: .later, datum: Testtijd.datum(2026, 11, 3), voorkeursMaanden: [11], nu: nu, kalender: k) == "In november")
        #expect(Wanneertekst.maak(status: .later, datum: Testtijd.datum(2027, 4, 3), voorkeursMaanden: [4], nu: nu, kalender: k) == "In april 2027")
    }

    @Test("Frequentie voor het Boekje")
    func frequentie() {
        #expect(Wanneertekst.frequentie(intervalMaanden: 1) == "Elke maand")
        #expect(Wanneertekst.frequentie(intervalMaanden: 6) == "Elk half jaar")
        #expect(Wanneertekst.frequentie(intervalMaanden: 12) == "Elk jaar")
        #expect(Wanneertekst.frequentie(intervalMaanden: 48) == "Elke 4 jaar")
        #expect(Wanneertekst.frequentie(intervalMaanden: 2) == "Elke 2 maanden")
        #expect(Wanneertekst.frequentie(intervalMaanden: nil) == "Bij aanleiding")
    }
}

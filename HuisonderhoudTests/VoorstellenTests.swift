import Foundation
import SwiftData
import Testing
@testable import Huisonderhoud

@MainActor
struct VoorstellenTests {
    private let nu = Testtijd.datum(2026, 10, 6)

    private func opzet(kenmerken: [String], catalogus: Catalogus? = nil) throws -> (Huisdienst, ModelContext, Woning) {
        let container = try ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let dienst = Huisdienst(catalogus: try catalogus ?? gebundeldeCatalogus(), planning: Testtijd.planning)
        let woning = dienst.maakSchema(kenmerken: kenmerken, context: context, nu: nu)
        return (dienst, context, woning)
    }

    @Test("Direct na de onboarding is er niets voor te stellen")
    func nietsTeStellen() throws {
        let (dienst, _, woning) = try opzet(kenmerken: Kenmerken.tags(voorKeuzes: ["cv-ketel", "tuin"]))
        #expect(dienst.voorstellen(voor: woning).isLeeg)
    }

    @Test("Een nieuw kenmerk stelt de bijpassende taken voor, zonder ze toe te voegen")
    func nieuwKenmerk() throws {
        let (dienst, _, woning) = try opzet(kenmerken: [])
        let voor = woning.alleTaken.count
        woning.kenmerken.append("zonnepanelen")
        let v = dienst.voorstellen(voor: woning)
        #expect(v.nieuw.map(\.id) == ["energie-zonnepanelen"])
        #expect(v.uitzetten.isEmpty)
        #expect(woning.alleTaken.count == voor, "er mag niets stilzwijgend zijn toegevoegd")
    }

    @Test("Een weggevallen kenmerk stelt deactiveren voor en verwijdert niets")
    func weggevallenKenmerk() throws {
        let (dienst, _, woning) = try opzet(kenmerken: Kenmerken.tags(voorKeuzes: ["boiler"]))
        let voor = woning.alleTaken.count
        woning.kenmerken.removeAll { $0 == "boiler" }
        let v = dienst.voorstellen(voor: woning)
        #expect(Set(v.uitzetten.compactMap(\.catalogusID)) == ["water-boiler-veiligheidsgroep", "water-boiler-ontkalken"])
        #expect(woning.alleTaken.count == voor)
        #expect(woning.alleTaken.allSatisfy { $0.isActief })
    }

    @Test("Een taak met meerdere tags blijft zolang één tag blijft (any-of)")
    func anyOfBlijft() throws {
        let (dienst, _, woning) = try opzet(kenmerken: ["gas", "houtkachel"])
        woning.kenmerken.removeAll { $0 == "gas" }
        let v = dienst.voorstellen(voor: woning)
        #expect(!v.uitzetten.contains { $0.catalogusID == "veiligheid-co-melder" })
    }

    @Test("Een nieuwe catalogusversie stelt nieuwe taken voor")
    func nieuweVersie() throws {
        let basis = try gebundeldeCatalogus()
        let (_, _, woning) = try opzet(kenmerken: ["tuin"], catalogus: basis)
        let extra = CatalogusTaak(id: "tuin-nieuwe-klus", titel: "Nieuwe klus", categorie: "Tuin", intervalMaanden: 12,
                                  uitvoering: .zelf, voorwaarde: ["tuin"], uitleg: "Uitleg")
        let nieuweCatalogus = Catalogus(meta: CatalogusMeta(versie: "0.2"), taken: basis.taken + [extra])
        let dienst2 = Huisdienst(catalogus: nieuweCatalogus, planning: Testtijd.planning)
        #expect(dienst2.voorstellen(voor: woning).nieuw.map(\.id) == ["tuin-nieuwe-klus"])
    }

    @Test("Keuze toepassen: toevoegen, uitgezet toevoegen, deactiveren en behouden")
    func keuzeToepassen() throws {
        let basis = try gebundeldeCatalogus()
        let (_, context, woning) = try opzet(kenmerken: Kenmerken.tags(voorKeuzes: ["boiler"]), catalogus: basis)
        let extra1 = CatalogusTaak(id: "algemeen-a", titel: "A", categorie: "Tuin", intervalMaanden: 12, uitvoering: .zelf, uitleg: "a")
        let extra2 = CatalogusTaak(id: "algemeen-b", titel: "B", categorie: "Tuin", intervalMaanden: 3, uitvoering: .zelf, uitleg: "b")
        let dienst = Huisdienst(catalogus: Catalogus(meta: CatalogusMeta(versie: "0.2"), taken: basis.taken + [extra1, extra2]), planning: Testtijd.planning)

        woning.kenmerken.removeAll { $0 == "boiler" }
        let v = dienst.voorstellen(voor: woning)
        #expect(Set(v.nieuw.map(\.id)) == ["algemeen-a", "algemeen-b"])
        let veiligheidsgroep = try #require(v.uitzetten.first { $0.catalogusID == "water-boiler-veiligheidsgroep" })
        let ontkalken = try #require(v.uitzetten.first { $0.catalogusID == "water-boiler-ontkalken" })

        dienst.pasVoorstellenToe(woning: woning, toevoegen: ["algemeen-a"], uitgezet: ["algemeen-b"],
                                 deactiveren: [ontkalken], behouden: [veiligheidsgroep], context: context, nu: nu)

        let a = try #require(woning.alleTaken.first { $0.catalogusID == "algemeen-a" })
        let b = try #require(woning.alleTaken.first { $0.catalogusID == "algemeen-b" })
        #expect(a.isActief && a.volgendeDatum != nil)
        #expect(!b.isActief, "een afgewezen voorstel blijft vindbaar als uitgezette taak")
        #expect(!ontkalken.isActief)
        #expect(veiligheidsgroep.isActief)
        #expect(woning.negeerVoorstellen == ["water-boiler-veiligheidsgroep"])
        // Daarna is er niets meer voor te stellen, en de versie is bijgewerkt.
        #expect(dienst.voorstellen(voor: woning).isLeeg)
        #expect(woning.catalogusVersie == "0.2")
    }

    @Test("Een taak die uit de catalogus verdwijnt wordt een eigen taak met de laatst bekende tekst en regels")
    func verdwenenUitCatalogus() throws {
        let basis = try gebundeldeCatalogus()
        let (_, context, woning) = try opzet(kenmerken: [], catalogus: basis)
        let weg = "dak-goten-najaar"
        let zonder = Catalogus(meta: CatalogusMeta(versie: "0.2"), taken: basis.taken.filter { $0.id != weg })
        let dienst = Huisdienst(catalogus: zonder, planning: Testtijd.planning)

        dienst.synchroniseer(woning: woning, context: context)
        let taak = try #require(woning.alleTaken.first { $0.eigenTitel == "Dakgoten reinigen in het najaar" || $0.eigenCategorie == "Dak en gevel" && $0.laatsteVoorkeursMaanden == [11] })
        #expect(taak.catalogusID == nil)
        let inhoud = taak.inhoud(in: zonder)
        #expect(inhoud.isEigen)
        #expect(inhoud.intervalMaanden == 12)
        #expect(inhoud.voorkeursMaanden == [11])
        #expect(!inhoud.uitleg.isEmpty)
        // De rest blijft ongemoeid.
        #expect(woning.alleTaken.count == basis.taken(voorKenmerken: []).count)
        #expect(woning.alleTaken.filter { $0.catalogusID == nil }.count == 1)

        // Afvinken laat hem gewoon terugkomen.
        dienst.vinkAf(taak, datum: Testtijd.datum(2026, 11, 5), uitvoerder: .zelf, context: context)
        #expect(Testtijd.onderdelen(taak.volgendeDatum!).jaar == 2027 && Testtijd.onderdelen(taak.volgendeDatum!).maand == 11)
    }

    @Test("Een gecorrigeerde tekst in de catalogus komt bij bestaande taken aan")
    func correctie() throws {
        let basis = try gebundeldeCatalogus()
        let (_, context, woning) = try opzet(kenmerken: [], catalogus: basis)
        let gecorrigeerd = basis.taken.map { t -> CatalogusTaak in
            guard t.id == "veiligheid-rookmelders-testen" else { return t }
            return CatalogusTaak(id: t.id, titel: "Rookmelders controleren", categorie: t.categorie, intervalMaanden: 2, maanden: [],
                                 uitvoering: t.uitvoering, duurMin: t.duurMin, voorwaarde: [], uitleg: "Nieuwe uitleg", waarschuwing: nil)
        }
        let dienst = Huisdienst(catalogus: Catalogus(meta: CatalogusMeta(versie: "0.2"), taken: gecorrigeerd), planning: Testtijd.planning)
        dienst.synchroniseer(woning: woning, context: context)
        let taak = try #require(woning.alleTaken.first { $0.catalogusID == "veiligheid-rookmelders-testen" })
        #expect(taak.inhoud(in: dienst.catalogus).titel == "Rookmelders controleren")
        #expect(taak.inhoud(in: dienst.catalogus).intervalMaanden == 2)
        #expect(taak.eigenTitel == "Rookmelders controleren")
        #expect(taak.eigenWaarschuwing == nil)
    }

    @Test("Eigen taak maken en verwijderen; catalogustaken kunnen niet worden verwijderd")
    func eigenTaak() throws {
        let (dienst, context, woning) = try opzet(kenmerken: [])
        let eigen = dienst.maakEigenTaak(woning: woning, titel: "  Dakkapel stofzuigen ", uitleg: "Met een zachte borstel.", categorie: "Dak en gevel",
                                         intervalMaanden: 6, uitvoering: .zelfOfVakman, eersteDatum: Testtijd.datum(2026, 11, 3, uur: 15), context: context)
        #expect(eigen.catalogusID == nil)
        #expect(eigen.eigenTitel == "Dakkapel stofzuigen")
        #expect(Testtijd.onderdelen(eigen.volgendeDatum!) == (2026, 11, 3))
        let inhoud = eigen.inhoud(in: dienst.catalogus)
        #expect(inhoud.isEigen && inhoud.uitvoering == .zelfOfVakman && inhoud.intervalMaanden == 6)

        let aantal = woning.alleTaken.count
        let catalogustaak = woning.alleTaken.first { $0.catalogusID != nil }!
        dienst.verwijder(catalogustaak, context: context)
        #expect(woning.alleTaken.count == aantal)
        dienst.verwijder(eigen, context: context)
        #expect(woning.alleTaken.count == aantal - 1)
    }
}

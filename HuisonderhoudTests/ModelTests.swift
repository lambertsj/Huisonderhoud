import Foundation
import SwiftData
import Testing
@testable import Huisonderhoud

@MainActor
struct ModelTests {
    private func container() throws -> ModelContainer {
        try ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test("Modellen laten zich opslaan met relaties")
    func opslaan() throws {
        let context = ModelContext(try container())
        let woning = Woning(naam: "Test", kenmerken: ["cv_ketel"])
        context.insert(woning)
        let cat = CatalogusTaak(id: "t", titel: "Titel", categorie: "Tuin", intervalMaanden: 12, uitvoering: .zelf, uitleg: "Uitleg", waarschuwing: "Pas op")
        let taak = Taak(catalogus: cat, volgendeDatum: Testtijd.datum(2026, 11, 1), woning: woning)
        context.insert(taak)
        let uitvoering = Uitvoering(datum: Testtijd.datum(2026, 10, 3), titelSnapshot: "Titel", categorieSnapshot: "Tuin", taak: taak, woning: woning)
        context.insert(uitvoering)
        try context.save()

        #expect(woning.alleTaken.count == 1)
        #expect(woning.alleUitvoeringen.count == 1)
        #expect(taak.laatsteUitvoering?.titelSnapshot == "Titel")
        #expect(taak.eigenWaarschuwing == "Pas op")
    }

    @Test("Het logboek blijft bestaan als een taak wordt verwijderd")
    func logboekOverleeftTaak() throws {
        let context = ModelContext(try container())
        let woning = Woning()
        context.insert(woning)
        let taak = Taak(eigenTitel: "Eigen", woning: woning)
        context.insert(taak)
        let uitvoering = Uitvoering(titelSnapshot: "Eigen", taak: taak, woning: woning)
        context.insert(uitvoering)
        try context.save()
        context.delete(taak)
        try context.save()
        #expect(woning.alleUitvoeringen.count == 1)
        #expect(woning.alleUitvoeringen.first?.taak == nil)
    }

    @Test("Inhoud komt uit de catalogus, of uit de laatst bekende tekst als de taak is verdwenen")
    func inhoud() throws {
        let catalogus = Catalogus(meta: CatalogusMeta(versie: "1"), taken: [
            CatalogusTaak(id: "a", titel: "Nieuwe titel", categorie: "Tuin", intervalMaanden: 6, maanden: [4], uitvoering: .zelfOfVakman, duurMin: 20, uitleg: "Nieuw"),
        ])
        let oud = CatalogusTaak(id: "weg", titel: "Oude titel", categorie: "Water", intervalMaanden: 12, uitvoering: .zelf, uitleg: "Oude uitleg")
        let bestaand = Taak(catalogus: catalogus.taken[0], volgendeDatum: nil, woning: nil)
        #expect(bestaand.inhoud(in: catalogus).titel == "Nieuwe titel")
        #expect(bestaand.inhoud(in: catalogus).intervalMaanden == 6)
        #expect(!bestaand.inhoud(in: catalogus).isEigen)

        let verdwenen = Taak(catalogus: oud, volgendeDatum: nil, woning: nil)
        let inhoud = verdwenen.inhoud(in: catalogus)
        #expect(inhoud.titel == "Oude titel")
        #expect(inhoud.uitleg == "Oude uitleg")
        #expect(inhoud.isEigen)
    }
}

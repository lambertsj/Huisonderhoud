import Foundation
import Testing
@testable import Huisonderhoud

struct EersteSchemaTests {
    let planning = Testtijd.planning
    let alleKenmerken = Array(Kenmerken.bereikbareTags)

    private func schema(nu: Date, kenmerken: [String]? = nil, laatsteKeer: [String: Date] = [:]) throws -> [EersteSchemaItem] {
        EersteSchema.maak(catalogus: try gebundeldeCatalogus(), kenmerken: kenmerken ?? alleKenmerken,
                          laatsteKeer: laatsteKeer, nu: nu, planning: planning)
    }

    @Test("Elke taak die bij het huis hoort krijgt precies één datum")
    func ookAllemaal() throws {
        let catalogus = try gebundeldeCatalogus()
        let items = try schema(nu: Testtijd.datum(2026, 10, 6))
        let verwacht = catalogus.taken(voorKenmerken: alleKenmerken).map(\.id)
        #expect(items.map(\.catalogusID) == verwacht)
    }

    @Test("Zonder kenmerken alleen taken voor elk huis")
    func zonderKenmerken() throws {
        let items = try schema(nu: Testtijd.datum(2026, 10, 6), kenmerken: [])
        let catalogus = try gebundeldeCatalogus()
        #expect(items.allSatisfy { catalogus.taak(met: $0.catalogusID)!.voorwaarde.isEmpty })
    }

    @Test("Nooit meer dan een vastgelegd aantal taken in de eerste week", arguments: [
        (2026, 1, 3), (2026, 4, 1), (2026, 4, 28), (2026, 10, 6), (2026, 10, 31), (2026, 11, 15), (2026, 12, 29),
    ])
    func eersteWeek(jaar: Int, maand: Int, dag: Int) throws {
        let nu = Testtijd.datum(jaar, maand, dag)
        let items = try schema(nu: nu)
        let weekLater = Testtijd.kalender.date(byAdding: .day, value: 7, to: Testtijd.kalender.startOfDay(for: nu))!
        let eersteWeek = items.filter { $0.volgendeDatum < weekLater }
        #expect(eersteWeek.count <= 3, "\(eersteWeek.count) taken in de eerste week")
    }

    @Test("Geen taak start voor vandaag, en niets staat al te laat bij het begin", arguments: [(2026, 10, 6), (2026, 12, 29), (2026, 3, 31)])
    func nietTeLaat(jaar: Int, maand: Int, dag: Int) throws {
        let nu = Testtijd.datum(jaar, maand, dag)
        for item in try schema(nu: nu) {
            let taak = try gebundeldeCatalogus().taak(met: item.catalogusID)!
            #expect(item.volgendeDatum >= Testtijd.kalender.startOfDay(for: nu), "\(item.catalogusID)")
            #expect(planning.status(volgendeDatum: item.volgendeDatum, voorkeursMaanden: taak.maanden, nu: nu) != .telaat,
                    "\(item.catalogusID) staat meteen te laat")
        }
    }

    @Test("Taken met voorkeursmaanden landen in een voorkeursmaand")
    func voorkeursmaand() throws {
        let catalogus = try gebundeldeCatalogus()
        for item in try schema(nu: Testtijd.datum(2026, 10, 6)) {
            let taak = catalogus.taak(met: item.catalogusID)!
            guard !taak.maanden.isEmpty, !EersteSchema.isZwaar(taak) else { continue }
            let maand = Testtijd.onderdelen(item.volgendeDatum).maand
            #expect(taak.maanden.contains(maand), "\(taak.id) in maand \(maand)")
        }
    }

    @Test("Korte intervallen starten tussen 1 en 4 weken vanaf nu")
    func kortInterval() throws {
        let nu = Testtijd.datum(2026, 10, 6)
        let catalogus = try gebundeldeCatalogus()
        let start = Testtijd.kalender.startOfDay(for: nu)
        for item in try schema(nu: nu) {
            let taak = catalogus.taak(met: item.catalogusID)!
            guard taak.maanden.isEmpty, let i = taak.intervalMaanden, i <= 3, !EersteSchema.isZwaar(taak) else { continue }
            let dagen = Testtijd.kalender.dateComponents([.day], from: start, to: item.volgendeDatum).day!
            #expect((7...28).contains(dagen), "\(taak.id): \(dagen) dagen")
        }
    }

    @Test("\"Weet ik niet\" plant zware taken in de komende drie maanden, gespreid")
    func weetIkNiet() throws {
        let nu = Testtijd.datum(2026, 10, 6)
        let items = try schema(nu: nu)
        let catalogus = try gebundeldeCatalogus()
        let zwaar = items.filter { EersteSchema.isZwaar(catalogus.taak(met: $0.catalogusID)!) }
        #expect(zwaar.count == 5)
        let grens = Testtijd.kalender.date(byAdding: .day, value: 90, to: Testtijd.kalender.startOfDay(for: nu))!
        #expect(zwaar.allSatisfy { $0.volgendeDatum <= grens })
        #expect(Set(zwaar.map(\.volgendeDatum)).count == zwaar.count)
    }

    @Test("Een opgegeven laatste keer wordt datum plus interval, gesnapt")
    func laatsteKeer() throws {
        let nu = Testtijd.datum(2026, 10, 6)
        let items = try schema(nu: nu, laatsteKeer: ["water-boiler-ontkalken": Testtijd.datum(2024, 3, 10)])
        let d = items.first { $0.catalogusID == "water-boiler-ontkalken" }!.volgendeDatum
        #expect(Testtijd.onderdelen(d) == (2028, 3, 10)) // 48 maanden, geen voorkeursmaanden
        let cv = try schema(nu: nu, laatsteKeer: ["verwarming-cv-onderhoud": Testtijd.datum(2025, 11, 1)])
        let dc = cv.first { $0.catalogusID == "verwarming-cv-onderhoud" }!.volgendeDatum
        // 1 nov 2025 + 12 mnd = 1 nov 2026 -> volgende voorkeursmaand [9, 10] = sep 2027.
        #expect(Testtijd.onderdelen(dc).maand == 9 && Testtijd.onderdelen(dc).jaar == 2027)
    }

    @Test("Aan het eind van de maand schuift de huidige voorkeursmaand door")
    func eindVanDeMaand() throws {
        let nu = Testtijd.datum(2026, 10, 28)
        let catalogus = try gebundeldeCatalogus()
        let items = try schema(nu: nu)
        let waterdruk = items.first { $0.catalogusID == "verwarming-cv-waterdruk" }!
        #expect(Testtijd.onderdelen(waterdruk.volgendeDatum).maand == 10)
        #expect(Testtijd.onderdelen(waterdruk.volgendeDatum).jaar == 2027)
        _ = catalogus
    }

    @Test("Het schema is deterministisch")
    func deterministisch() throws {
        let nu = Testtijd.datum(2026, 10, 6)
        #expect(try schema(nu: nu) == schema(nu: nu))
    }
}

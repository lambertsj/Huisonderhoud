import Foundation
import PDFKit
import SwiftData
import Testing
import UIKit
@testable import Huisonderhoud

@MainActor
struct BoekjeTests {
    private func opzet(kenmerken: [String] = []) throws -> (Huisdienst, ModelContext, Woning) {
        let container = try ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let dienst = Huisdienst(catalogus: try gebundeldeCatalogus(), planning: Testtijd.planning)
        let woning = dienst.maakSchema(kenmerken: kenmerken, context: context, nu: Testtijd.datum(2026, 10, 6))
        woning.naam = "Huis aan de Dijk"
        woning.bouwjaar = 1985
        return (dienst, context, woning)
    }

    private func foto() -> Data {
        let r = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600), format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }())
        return r.jpegData(withCompressionQuality: 0.9) { c in UIColor.orange.setFill(); c.fill(CGRect(x: 0, y: 0, width: 800, height: 600)) }
    }

    @Test("Dossier-inhoud: jaren aflopend, nieuwste regel eerst, maximaal drie foto's")
    func inhoudVolgorde() throws {
        let (dienst, context, woning) = try opzet()
        let taken = woning.alleTaken
        dienst.vinkAf(taken[0], datum: Testtijd.datum(2025, 3, 1), uitvoerder: .zelf, context: context)
        dienst.vinkAf(taken[1], datum: Testtijd.datum(2026, 2, 1), uitvoerder: .vakman, fotos: [foto(), foto(), foto(), foto(), foto()], context: context)
        dienst.vinkAf(taken[2], datum: Testtijd.datum(2026, 8, 1), uitvoerder: .zelf, context: context)
        let inhoud = DossierInhoud.maak(woning: woning, datum: Testtijd.datum(2026, 10, 6), kalender: Testtijd.kalender)
        #expect(inhoud.jaren.map(\.jaar) == [2026, 2025])
        #expect(inhoud.jaren[0].regels.map(\.datum) == [Testtijd.datum(2026, 8, 1), Testtijd.datum(2026, 2, 1)])
        #expect(inhoud.jaren[0].regels[1].fotos.count == 3)
        #expect(inhoud.aantalRegels == 3)
    }

    @Test("Het pdf is een geldig A4-document met voorblad, apparaten en logboek")
    func pdfInhoud() throws {
        let (dienst, context, woning) = try opzet()
        context.insert(Apparaat(soort: "Cv-ketel", merk: "Remeha", model: "Avanta", serienummer: "SN-12345",
                                aangeschaftOp: Testtijd.datum(2019, 5, 1), garantieTot: Testtijd.datum(2029, 5, 1),
                                installateurNaam: "Installatie De Boer", woning: woning))
        dienst.vinkAf(woning.alleTaken.first { $0.catalogusID == "veiligheid-rookmelders-testen" }!, datum: Testtijd.datum(2026, 9, 1), uitvoerder: .vakman, notitie: "Alles in orde", fotos: [foto()], context: context)
        let inhoud = DossierInhoud.maak(woning: woning, datum: Testtijd.datum(2026, 10, 6), kalender: Testtijd.kalender)
        let data = DossierPDF.maak(inhoud)
        let document = try #require(PDFDocument(data: data))
        #expect(document.pageCount >= 2)
        let rect = document.page(at: 0)!.bounds(for: .mediaBox)
        #expect(abs(rect.width - 595.28) < 1 && abs(rect.height - 841.89) < 1)
        let tekst = document.string ?? ""
        for verwacht in ["Onderhoudsdossier", "Huis aan de Dijk", "Bouwjaar 1985", "Remeha", "SN-12345", "Installatie De Boer", "Alles in orde", "Rookmelders testen", "2026"] {
            #expect(tekst.contains(verwacht), "'\(verwacht)' ontbreekt in het pdf")
        }
    }

    @Test("Veel regels lopen netjes over meerdere pagina's")
    func pagineren() throws {
        let (dienst, context, woning) = try opzet()
        let taak = woning.alleTaken[0]
        for i in 0..<120 {
            let d = Testtijd.kalender.date(byAdding: .day, value: -i * 5, to: Testtijd.datum(2026, 10, 1))!
            dienst.vinkAf(taak, datum: d, uitvoerder: i % 2 == 0 ? .zelf : .vakman, notitie: "Notitie nummer \(i), met wat extra tekst zodat de regel langer wordt dan een enkele regel op het papier.", context: context)
        }
        let inhoud = DossierInhoud.maak(woning: woning, datum: Testtijd.datum(2026, 10, 6), kalender: Testtijd.kalender)
        let document = try #require(PDFDocument(data: DossierPDF.maak(inhoud)))
        #expect(document.pageCount >= 8, "pagina's: \(document.pageCount)")
        #expect((document.string ?? "").contains("Notitie nummer 119"))
    }

    @Test("Een leeg dossier geeft toch een geldig pdf")
    func leeg() throws {
        let (_, _, woning) = try opzet()
        let inhoud = DossierInhoud.maak(woning: woning, datum: Testtijd.datum(2026, 10, 6), kalender: Testtijd.kalender)
        let document = try #require(PDFDocument(data: DossierPDF.maak(inhoud)))
        #expect(document.pageCount == 2)
        #expect((document.string ?? "").contains("Er is nog niets afgevinkt."))
    }

    @Test("Bewerken past de uitvoering aan en herberekent de volgende datum")
    func bewerken() throws {
        let (dienst, context, woning) = try opzet()
        let taak = woning.alleTaken.first { $0.catalogusID == "veiligheid-rookmelders-testen" }!
        let u = dienst.vinkAf(taak, datum: Testtijd.datum(2026, 10, 6), uitvoerder: .zelf, fotos: [foto()], context: context)
        #expect(Testtijd.onderdelen(taak.volgendeDatum!) == (2026, 11, 6))
        dienst.bewerk(u, datum: Testtijd.datum(2026, 10, 1), uitvoerder: .vakman, uitvoerderNaam: " Jansen ", notitie: " ok ", fotos: [], context: context)
        #expect(u.uitvoerder == .vakman && u.uitvoerderNaam == "Jansen" && u.notitie == "ok")
        #expect(u.alleBijlagen.isEmpty)
        #expect(Testtijd.onderdelen(taak.volgendeDatum!) == (2026, 11, 1))
        dienst.bewerk(u, datum: Testtijd.datum(2026, 10, 1), uitvoerder: .zelf, uitvoerderNaam: "Jansen", notitie: "", fotos: [], context: context)
        #expect(u.uitvoerderNaam == nil)
    }

    @Test("Verwijderen haalt de uitvoering weg en laat de taak leven")
    func verwijderen() throws {
        let (dienst, context, woning) = try opzet()
        let taak = woning.alleTaken[0]
        let eerste = dienst.vinkAf(taak, datum: Testtijd.datum(2026, 5, 1), uitvoerder: .zelf, context: context)
        let tweede = dienst.vinkAf(taak, datum: Testtijd.datum(2026, 9, 1), uitvoerder: .zelf, fotos: [foto()], context: context)
        dienst.verwijder(tweede, context: context)
        #expect(woning.alleUitvoeringen.count == 1)
        #expect(try context.fetch(FetchDescriptor<Bijlage>()).isEmpty)
        // De volgende datum volgt weer de overgebleven uitvoering.
        let verwacht = Testtijd.planning.volgendeDatum(na: eerste.datum, intervalMaanden: taak.inhoud(in: dienst.catalogus).intervalMaanden,
                                                       voorkeursMaanden: taak.inhoud(in: dienst.catalogus).voorkeursMaanden,
                                                       dagInMaand: Planning.spreidingsdag(voor: taak.catalogusID!))
        #expect(taak.volgendeDatum == verwacht)
    }
}

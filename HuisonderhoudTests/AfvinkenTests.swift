import Foundation
import SwiftData
import Testing
import UIKit
@testable import Huisonderhoud

@MainActor
struct AfvinkenTests {
    private func opzet(kenmerken: [String] = []) throws -> (Huisdienst, ModelContext, Woning) {
        let container = try ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let dienst = Huisdienst(catalogus: try gebundeldeCatalogus(), planning: Testtijd.planning)
        let woning = dienst.maakSchema(kenmerken: kenmerken, context: context, nu: Testtijd.datum(2026, 10, 6))
        return (dienst, context, woning)
    }

    private func taak(_ id: String, in woning: Woning) -> Taak {
        woning.alleTaken.first { $0.catalogusID == id }!
    }

    private func jpeg(breedte: Int, hoogte: Int) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: breedte, height: hoogte), format: {
            let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f
        }())
        return renderer.jpegData(withCompressionQuality: 1) { ctx in
            UIColor.systemTeal.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: breedte, height: hoogte))
        }
    }

    @Test("Afvinken maakt een uitvoering met snapshots en berekent de volgende datum")
    func afvinken() throws {
        let (dienst, context, woning) = try opzet()
        let t = taak("veiligheid-rookmelders-testen", in: woning)
        let datum = Testtijd.datum(2026, 10, 6)
        let u = dienst.vinkAf(t, datum: datum, uitvoerder: .zelf, notitie: "  Batterij nieuw  ", context: context)
        #expect(u.titelSnapshot == "Rookmelders testen")
        #expect(u.categorieSnapshot == "Veiligheid")
        #expect(u.notitie == "Batterij nieuw")
        #expect(u.woning === woning)
        #expect(t.alleUitvoeringen.count == 1)
        #expect(woning.alleUitvoeringen.count == 1)
        // Interval 1 maand, geen voorkeursmaanden.
        #expect(Testtijd.onderdelen(t.volgendeDatum!) == (2026, 11, 6))
    }

    @Test("Met voorkeursmaanden snapt de volgende datum naar de voorkeursmaand")
    func voorkeursmaand() throws {
        let (dienst, context, woning) = try opzet()
        let t = taak("dak-goten-najaar", in: woning) // 12 maanden, voorkeur november
        dienst.vinkAf(t, datum: Testtijd.datum(2026, 11, 28), uitvoerder: .zelf, context: context)
        let d = Testtijd.onderdelen(t.volgendeDatum!)
        #expect(d.jaar == 2027 && d.maand == 11, "\(d)")
    }

    @Test("Late afvinking schuift niet door naar januari")
    func nietDoorschuiven() throws {
        let (dienst, context, woning) = try opzet()
        let t = taak("dak-goten-najaar", in: woning)
        dienst.vinkAf(t, datum: Testtijd.datum(2026, 11, 2), uitvoerder: .zelf, context: context)
        #expect(Testtijd.onderdelen(t.volgendeDatum!).maand == 11)
    }

    @Test("Standaard uitvoerder: zelf_of_vakman wordt zelf, vakman blijft vakman")
    func standaardUitvoerder() throws {
        let (dienst, _, woning) = try opzet(kenmerken: Kenmerken.tags(voorKeuzes: ["cv-ketel"]))
        #expect(dienst.standaardUitvoerder(voor: taak("dak-goten-najaar", in: woning)) == .zelf)
        #expect(dienst.standaardUitvoerder(voor: taak("veiligheid-rookmelders-testen", in: woning)) == .zelf)
        #expect(dienst.standaardUitvoerder(voor: taak("verwarming-cv-onderhoud", in: woning)) == .vakman)
    }

    @Test("Foto's worden verkleind en als bijlage bewaard")
    func fotos() throws {
        let (dienst, context, woning) = try opzet()
        let groot = jpeg(breedte: 3000, hoogte: 1500)
        let u = dienst.vinkAf(taak("veiligheid-rookmelders-testen", in: woning), uitvoerder: .zelf, fotos: [groot, Data("geen foto".utf8)], context: context)
        #expect(u.alleBijlagen.count == 1) // de ongeldige data wordt overgeslagen
        let opgeslagen = try #require(u.alleBijlagen.first?.data)
        let maat = try #require(Fotoverkleiner.afmetingen(opgeslagen))
        #expect(max(maat.breedte, maat.hoogte) == 2000)
        #expect(maat.breedte == 2000 && maat.hoogte == 1000)
        #expect(opgeslagen.count < groot.count)
        #expect(u.alleBijlagen.first?.soort == .foto)
    }

    @Test("Een kleine foto wordt niet opgeblazen")
    func kleineFoto() throws {
        let klein = jpeg(breedte: 400, hoogte: 300)
        let verkleind = try #require(Fotoverkleiner.verklein(klein))
        let maat = try #require(Fotoverkleiner.afmetingen(verkleind))
        #expect(maat.breedte <= 400 && maat.hoogte <= 300)
    }

    @Test("Taak uitzetten haalt hem uit de meldingen; aanzetten zet een achterstand op vandaag")
    func uitzetten() throws {
        let (dienst, context, woning) = try opzet()
        let t = taak("veiligheid-rookmelders-testen", in: woning)
        dienst.zetActief(false, voor: t, context: context)
        #expect(!t.isActief)
        let kandidaat = t.meldingKandidaat(titel: "x")
        #expect(Meldingplanner.plan([kandidaat], nu: Testtijd.datum(2020, 1, 1), kalender: Testtijd.kalender).isEmpty)

        t.volgendeDatum = Testtijd.datum(2026, 1, 5)
        dienst.zetActief(true, voor: t, nu: Testtijd.datum(2026, 10, 6), context: context)
        #expect(t.isActief)
        #expect(Testtijd.onderdelen(t.volgendeDatum!) == (2026, 10, 6))
    }

    @Test("Een taak zonder interval komt niet terug na afvinken")
    func zonderInterval() throws {
        let (dienst, context, woning) = try opzet()
        let eigen = Taak(eigenTitel: "Eenmalig", eigenUitleg: "Doe dit", eigenCategorie: "Tuin", intervalMaanden: nil,
                         volgendeDatum: Testtijd.datum(2026, 10, 10), woning: woning)
        context.insert(eigen)
        dienst.vinkAf(eigen, datum: Testtijd.datum(2026, 10, 10), uitvoerder: .zelf, context: context)
        #expect(eigen.volgendeDatum == nil)
        #expect(woning.alleUitvoeringen.first?.titelSnapshot == "Eenmalig")
    }

    @Test("Statusregel van het taakdetail")
    func taakregel() {
        #expect(Wanneertekst.taakregel(status: .later, wanneer: "In november", uitvoering: .zelfOfVakman, duurMin: 90, heeftDatum: true)
                == "In november, zelf of vakman, 90 minuten")
        #expect(Wanneertekst.taakregel(status: .telaat, wanneer: "sinds september", uitvoering: .vakman, duurMin: nil, heeftDatum: true)
                == "Te laat, sinds september, vakman")
        #expect(Wanneertekst.taakregel(status: .later, wanneer: "", uitvoering: .zelf, duurMin: 5, heeftDatum: false)
                == "Bij aanleiding, zelf, 5 minuten")
    }
}

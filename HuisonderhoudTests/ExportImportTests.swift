import Foundation
import SwiftData
import Testing
import UIKit
@testable import Huisonderhoud

@MainActor
struct ExportImportTests {
    private func nieuweContext() throws -> ModelContext {
        ModelContext(try ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
    }

    private func foto() -> Data {
        let r = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200), format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; return f }())
        return r.jpegData(withCompressionQuality: 0.8) { c in UIColor.purple.setFill(); c.fill(CGRect(x: 0, y: 0, width: 300, height: 200)) }
    }

    /// Een rijk gevulde opslag: woning, schema, apparaat met foto, uitvoeringen met foto's, een eigen taak.
    private func vul(_ context: ModelContext) throws -> (Huisdienst, Woning) {
        let dienst = Huisdienst(catalogus: try gebundeldeCatalogus(), planning: Testtijd.planning)
        let woning = dienst.maakSchema(kenmerken: Kenmerken.tags(voorKeuzes: ["cv-ketel", "tuin", "boiler"]), context: context, nu: Testtijd.datum(2026, 10, 6))
        woning.naam = "Huis aan de Dijk"; woning.bouwjaar = 1985; woning.woningtype = "Hoekwoning"
        woning.eigenaarSinds = Testtijd.datum(2023, 6, 1); woning.negeerVoorstellen = ["tuin-bomen-snoeien"]
        let apparaat = Apparaat(soort: "Cv-ketel", merk: "Remeha", model: "Avanta", serienummer: "SN-1", aangeschaftOp: Testtijd.datum(2019, 1, 1),
                                garantieTot: Testtijd.datum(2029, 1, 1), installateurNaam: "De Boer", notitie: "Achter in de kast", woning: woning)
        context.insert(apparaat)
        let typeplaatje = Bijlage(soort: .foto, titel: "Typeplaatje", data: foto())
        context.insert(typeplaatje)
        typeplaatje.apparaat = apparaat
        woning.alleTaken.first { $0.catalogusID == "verwarming-cv-onderhoud" }?.apparaat = apparaat
        let eigen = Taak(eigenTitel: "Dakkapel stofzuigen", eigenUitleg: "Eigen taak", eigenCategorie: "Dak en gevel", intervalMaanden: 6,
                         voorkeursMaanden: [3, 9], volgendeDatum: Testtijd.datum(2027, 3, 1), woning: woning)
        eigen.herinneringAan = false
        context.insert(eigen)
        for (i, t) in woning.alleTaken.prefix(4).enumerated() {
            dienst.vinkAf(t, datum: Testtijd.datum(2026, 5 + i, 3), uitvoerder: i == 1 ? .vakman : .zelf, notitie: "Notitie \(i) met é en ë", fotos: i == 0 ? [foto(), foto()] : [], context: context)
        }
        let eerste = woning.alleUitvoeringen.first!
        eerste.uitvoerderNaam = "Jansen"; eerste.kostenCenten = 12_550
        try context.save()
        return (dienst, woning)
    }

    private func wis(_ context: ModelContext) throws {
        try context.delete(model: Woning.self)
        try context.delete(model: Taak.self)
        try context.delete(model: Apparaat.self)
        try context.delete(model: Uitvoering.self)
        try context.delete(model: Bijlage.self)
        try context.save()
    }

    private let vasteDatum = Testtijd.datum(2026, 10, 6)

    @Test("Rondreis: export, wissen, import geeft gelijke data")
    func rondreis() throws {
        let context = try nieuweContext()
        _ = try vul(context)
        let voor = try Export.maak(context: context, nu: vasteDatum, catalogusVersie: "0.1")
        #expect(voor.woningen.count == 1 && voor.taken.count > 20 && voor.uitvoeringen.count == 4)
        #expect(voor.bijlagen.count == 3)
        let bestand = try voor.data()

        try wis(context)
        #expect(try context.fetch(FetchDescriptor<Taak>()).isEmpty)

        let gelezen = try Export.lees(bestand)
        #expect(gelezen == voor)
        let resultaat = try Import.voerUit(gelezen, context: context, bestaande: .overslaan)
        #expect(resultaat.toegevoegd == voor.woningen.count + voor.taken.count + voor.apparaten.count + voor.uitvoeringen.count + voor.bijlagen.count)
        #expect(resultaat.overgeslagen == 0 && resultaat.losseVerwijzingen == 0)

        let na = try Export.maak(context: context, nu: vasteDatum, catalogusVersie: "0.1")
        #expect(na == voor)
        // De relaties zijn echt hersteld, niet alleen de velden.
        let woning = try #require(try context.fetch(FetchDescriptor<Woning>()).first)
        #expect(woning.alleTaken.count == voor.taken.count)
        #expect(woning.alleUitvoeringen.count == 4)
        #expect(woning.alleApparaten.first?.alleBijlagen.count == 1)
        #expect(woning.alleUitvoeringen.allSatisfy { $0.taak != nil })
        #expect(woning.alleTaken.first { $0.catalogusID == "verwarming-cv-onderhoud" }?.apparaat?.merk == "Remeha")
    }

    @Test("Importeren is dubbel-veilig: twee keer importeren geeft geen dubbelen")
    func tweeKeer() throws {
        let context = try nieuweContext()
        _ = try vul(context)
        let export = try Export.maak(context: context, nu: vasteDatum)
        let analyse = try Import.analyseer(export, context: context)
        #expect(analyse.nieuw == 0 && analyse.bestaand > 0)
        let resultaat = try Import.voerUit(export, context: context, bestaande: .overslaan)
        #expect(resultaat.toegevoegd == 0 && resultaat.overgeslagen == analyse.bestaand)
        #expect(try context.fetch(FetchDescriptor<Woning>()).count == 1)
        #expect(try Export.maak(context: context, nu: vasteDatum) == export)
    }

    @Test("Importeren is additief: bestaande data blijft, nieuwe komt erbij")
    func additief() throws {
        let bron = try nieuweContext()
        _ = try vul(bron)
        let export = try Export.maak(context: bron, nu: vasteDatum)

        let doel = try nieuweContext()
        let andereWoning = Woning(naam: "Zomerhuisje")
        doel.insert(andereWoning)
        try doel.save()
        let resultaat = try Import.voerUit(export, context: doel, bestaande: .overslaan)
        #expect(resultaat.toegevoegd > 0)
        let namen = try doel.fetch(FetchDescriptor<Woning>()).map(\.naam).sorted()
        #expect(namen == ["Huis aan de Dijk", "Zomerhuisje"])
    }

    @Test("Overschrijven na bevestiging past bestaande entiteiten aan")
    func overschrijven() throws {
        let context = try nieuweContext()
        _ = try vul(context)
        var export = try Export.maak(context: context, nu: vasteDatum)
        export.woningen[0].naam = "Nieuwe naam"
        export.uitvoeringen[0].notitie = "Aangepast"

        try Import.voerUit(export, context: context, bestaande: .overslaan)
        #expect(try context.fetch(FetchDescriptor<Woning>()).first?.naam == "Huis aan de Dijk")

        let resultaat = try Import.voerUit(export, context: context, bestaande: .overschrijven)
        #expect(resultaat.overschreven == export.woningen.count + export.taken.count + export.apparaten.count + export.uitvoeringen.count + export.bijlagen.count)
        #expect(try context.fetch(FetchDescriptor<Woning>()).first?.naam == "Nieuwe naam")
        #expect(try context.fetch(FetchDescriptor<Woning>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<Uitvoering>()).count == 4)
        let woning = try #require(try context.fetch(FetchDescriptor<Woning>()).first)
        #expect(woning.alleUitvoeringen.count == 4)
    }

    @Test("Foto's overleven de rondreis byte voor byte")
    func fotosIntact() throws {
        let context = try nieuweContext()
        _ = try vul(context)
        let voor = try context.fetch(FetchDescriptor<Bijlage>()).compactMap(\.data).map(\.count).sorted()
        let bestand = try Export.maak(context: context).data()
        try wis(context)
        try Import.voerUit(try Export.lees(bestand), context: context, bestaande: .overslaan)
        let na = try context.fetch(FetchDescriptor<Bijlage>()).compactMap(\.data).map(\.count).sorted()
        #expect(voor == na && !voor.isEmpty)
    }

    @Test("Een bestand uit een nieuwere versie of kapotte data geeft een duidelijke fout")
    func fouten() throws {
        #expect(throws: Export.Fout.self) { try Export.lees(Data("geen json".utf8)) }
        #expect(throws: Export.Fout.self) { try Export.lees(Data("{\"versie\": 1}".utf8)) }
        #expect(throws: Export.Fout.nieuwereVersie(2)) { try Export.lees(Data("{\"versie\": 2, \"iets\": []}".utf8)) }
    }

    @Test("Losse verwijzingen worden geteld en veroorzaken geen crash")
    func losseVerwijzing() throws {
        let context = try nieuweContext()
        let dienst = Huisdienst(catalogus: try gebundeldeCatalogus(), planning: Testtijd.planning)
        dienst.maakSchema(kenmerken: [], context: context, nu: vasteDatum)
        var export = try Export.maak(context: context, nu: vasteDatum)
        export.taken[0].woningID = UUID()
        try wis(context)
        let resultaat = try Import.voerUit(export, context: context, bestaande: .overslaan)
        #expect(resultaat.losseVerwijzingen == 1)
    }

    @Test("Het exportbestand heeft versie 1 en een datum")
    func kop() throws {
        let context = try nieuweContext()
        _ = try vul(context)
        let json = try Export.maak(context: context, nu: vasteDatum).data()
        let tekst = String(decoding: json, as: UTF8.self)
        #expect(tekst.contains("\"versie\" : 1"))
        #expect(tekst.contains("\"geexporteerdOp\""))
    }
}

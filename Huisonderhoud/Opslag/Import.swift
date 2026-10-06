import Foundation
import SwiftData

/// Importeren is additief en dubbel-veilig: een bestaande UUID wordt overgeslagen of, na
/// bevestiging van de gebruiker, overschreven. Er wordt nooit iets verwijderd.
enum Import {
    enum Bestaande { case overslaan, overschrijven }

    struct Analyse: Equatable {
        var nieuw: Int
        var bestaand: Int
        var totaal: Int { nieuw + bestaand }
    }

    struct Resultaat: Equatable {
        var toegevoegd: Int
        var overschreven: Int
        var overgeslagen: Int
        /// Verwijzingen naar iets dat niet in het bestand of de opslag zat.
        var losseVerwijzingen: Int
    }

    static func analyseer(_ export: Export, context: ModelContext) throws -> Analyse {
        let bestaand = Set(try bestaandeIDs(context))
        let alle = ids(van: export)
        let dubbel = alle.filter { bestaand.contains($0) }.count
        return Analyse(nieuw: alle.count - dubbel, bestaand: dubbel)
    }

    @discardableResult
    static func voerUit(_ export: Export, context: ModelContext, bestaande: Bestaande) throws -> Resultaat {
        var woningen = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Woning>()).map { ($0.id, $0) })
        var taken = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Taak>()).map { ($0.id, $0) })
        var apparaten = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Apparaat>()).map { ($0.id, $0) })
        var uitvoeringen = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Uitvoering>()).map { ($0.id, $0) })
        var bijlagen = Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<Bijlage>()).map { ($0.id, $0) })

        var resultaat = Resultaat(toegevoegd: 0, overschreven: 0, overgeslagen: 0, losseVerwijzingen: 0)
        /// Alleen aan deze entiteiten worden relaties gezet (nieuwe, of overschreven).
        var bij: Set<UUID> = []

        func verwerk<T>(_ id: UUID, in dict: inout [UUID: T], maak: () -> T, vul: (T) -> Void) {
            if let bestaand = dict[id] {
                switch bestaande {
                case .overslaan: resultaat.overgeslagen += 1
                case .overschrijven:
                    vul(bestaand)
                    bij.insert(id)
                    resultaat.overschreven += 1
                }
            } else {
                let nieuw = maak()
                vul(nieuw)
                dict[id] = nieuw
                bij.insert(id)
                resultaat.toegevoegd += 1
            }
        }

        for d in export.woningen {
            verwerk(d.id, in: &woningen, maak: { let w = Woning(); w.id = d.id; context.insert(w); return w }) { w in
                w.naam = d.naam; w.bouwjaar = d.bouwjaar; w.woningtype = d.woningtype; w.kenmerken = d.kenmerken
                w.eigenaarSinds = d.eigenaarSinds; w.catalogusVersie = d.catalogusVersie; w.negeerVoorstellen = d.negeerVoorstellen
            }
        }
        for d in export.apparaten {
            verwerk(d.id, in: &apparaten, maak: { let a = Apparaat(); a.id = d.id; context.insert(a); return a }) { a in
                a.soort = d.soort; a.merk = d.merk; a.model = d.model; a.serienummer = d.serienummer
                a.aangeschaftOp = d.aangeschaftOp; a.garantieTot = d.garantieTot
                a.installateurNaam = d.installateurNaam; a.notitie = d.notitie
            }
        }
        for d in export.taken {
            verwerk(d.id, in: &taken, maak: { let t = Taak(); t.id = d.id; context.insert(t); return t }) { t in
                t.catalogusID = d.catalogusID; t.eigenTitel = d.eigenTitel; t.eigenUitleg = d.eigenUitleg
                t.eigenCategorie = d.eigenCategorie; t.eigenWaarschuwing = d.eigenWaarschuwing
                t.eigenUitvoering = d.eigenUitvoering; t.eigenDuurMin = d.eigenDuurMin
                t.intervalMaanden = d.intervalMaanden; t.voorkeursMaanden = d.voorkeursMaanden
                t.volgendeDatum = d.volgendeDatum; t.isActief = d.isActief; t.herinneringAan = d.herinneringAan
            }
        }
        for d in export.uitvoeringen {
            verwerk(d.id, in: &uitvoeringen, maak: { let u = Uitvoering(); u.id = d.id; context.insert(u); return u }) { u in
                u.datum = d.datum; u.titelSnapshot = d.titelSnapshot; u.categorieSnapshot = d.categorieSnapshot
                u.uitvoerderRaw = d.uitvoerder; u.uitvoerderNaam = d.uitvoerderNaam; u.notitie = d.notitie
                u.kostenCenten = d.kostenCenten
            }
        }
        for d in export.bijlagen {
            verwerk(d.id, in: &bijlagen, maak: { let b = Bijlage(); b.id = d.id; context.insert(b); return b }) { b in
                b.soortRaw = d.soort; b.titel = d.titel; b.aangemaakt = d.aangemaakt; b.data = d.data
            }
        }

        // Relaties, pas als alles bestaat.
        func zoek<T>(_ id: UUID?, in dict: [UUID: T]) -> T? {
            guard let id else { return nil }
            if let gevonden = dict[id] { return gevonden }
            resultaat.losseVerwijzingen += 1
            return nil
        }
        for d in export.apparaten where bij.contains(d.id) { apparaten[d.id]?.woning = zoek(d.woningID, in: woningen) }
        for d in export.taken where bij.contains(d.id) {
            taken[d.id]?.woning = zoek(d.woningID, in: woningen)
            taken[d.id]?.apparaat = zoek(d.apparaatID, in: apparaten)
        }
        for d in export.uitvoeringen where bij.contains(d.id) {
            uitvoeringen[d.id]?.woning = zoek(d.woningID, in: woningen)
            uitvoeringen[d.id]?.taak = zoek(d.taakID, in: taken)
        }
        for d in export.bijlagen where bij.contains(d.id) {
            bijlagen[d.id]?.woning = zoek(d.woningID, in: woningen)
            bijlagen[d.id]?.apparaat = zoek(d.apparaatID, in: apparaten)
            bijlagen[d.id]?.uitvoering = zoek(d.uitvoeringID, in: uitvoeringen)
        }
        try context.save()
        return resultaat
    }

    private static func ids(van export: Export) -> [UUID] {
        export.woningen.map(\.id) + export.taken.map(\.id) + export.apparaten.map(\.id)
            + export.uitvoeringen.map(\.id) + export.bijlagen.map(\.id)
    }

    private static func bestaandeIDs(_ context: ModelContext) throws -> [UUID] {
        try context.fetch(FetchDescriptor<Woning>()).map(\.id) + context.fetch(FetchDescriptor<Taak>()).map(\.id)
            + context.fetch(FetchDescriptor<Apparaat>()).map(\.id) + context.fetch(FetchDescriptor<Uitvoering>()).map(\.id)
            + context.fetch(FetchDescriptor<Bijlage>()).map(\.id)
    }
}

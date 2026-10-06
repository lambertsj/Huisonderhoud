import Foundation
import Observation
import SwiftData

/// Eén plek voor de handelingen op de gebruikersdata. Views blijven dun en roepen dit aan.
@Observable
@MainActor
final class Huisdienst {
    let catalogus: Catalogus
    let planning: Planning

    init(catalogus: Catalogus, planning: Planning = Planning()) {
        self.catalogus = catalogus
        self.planning = planning
    }

    // MARK: Onboarding

    /// Maakt de woning en het eerste schema. Zware taken staan op "Weet ik niet" tot
    /// `pasLaatsteKeerToe` ze corrigeert.
    @discardableResult
    func maakSchema(kenmerken: [String], context: ModelContext, nu: Date = Date()) -> Woning {
        let woning = Woning(naam: "Mijn huis", kenmerken: kenmerken, catalogusVersie: catalogus.versie)
        context.insert(woning)
        let items = EersteSchema.maak(catalogus: catalogus, kenmerken: kenmerken, nu: nu, planning: planning)
        for item in items {
            guard let cat = catalogus.taak(met: item.catalogusID) else { continue }
            context.insert(Taak(catalogus: cat, volgendeDatum: item.volgendeDatum, woning: woning))
        }
        try? context.save()
        return woning
    }

    func zwareTaken(voor woning: Woning) -> [CatalogusTaak] {
        EersteSchema.zwareTaken(catalogus: catalogus, kenmerken: woning.kenmerken)
    }

    /// Antwoorden uit "Wanneer deed je dit voor het laatst?". Taken zonder antwoord blijven staan.
    func pasLaatsteKeerToe(_ antwoorden: [String: Date], woning: Woning, context: ModelContext, nu: Date = Date()) {
        guard !antwoorden.isEmpty else { return }
        let items = EersteSchema.maak(catalogus: catalogus, kenmerken: woning.kenmerken,
                                      laatsteKeer: antwoorden, nu: nu, planning: planning)
        let datums = Dictionary(items.map { ($0.catalogusID, $0.volgendeDatum) }, uniquingKeysWith: { eerste, _ in eerste })
        for taak in woning.alleTaken {
            if let id = taak.catalogusID, antwoorden[id] != nil, let datum = datums[id] {
                taak.volgendeDatum = datum
            }
        }
        try? context.save()
    }

    // MARK: Afvinken

    /// Standaard uitvoerder bij het afvinken: `zelf_of_vakman` wordt `zelf`.
    func standaardUitvoerder(voor taak: Taak) -> Uitvoerder {
        taak.inhoud(in: catalogus).uitvoering == .vakman ? .vakman : .zelf
    }

    /// Maakt de uitvoering (met snapshots, notitie en foto's) en berekent de volgende datum.
    /// Het plannen van meldingen doet de aanroeper daarna met `herplanMeldingen`.
    @discardableResult
    func vinkAf(_ taak: Taak, datum: Date = Date(), uitvoerder: Uitvoerder, notitie: String = "",
                fotos: [Data] = [], context: ModelContext) -> Uitvoering {
        let inhoud = taak.inhoud(in: catalogus)
        let uitvoering = Uitvoering(datum: datum, titelSnapshot: inhoud.titel, categorieSnapshot: inhoud.categorie,
                                    uitvoerder: uitvoerder, notitie: notitie.trimmingCharacters(in: .whitespacesAndNewlines),
                                    taak: taak, woning: taak.woning)
        context.insert(uitvoering)
        for data in fotos {
            guard let verkleind = Fotoverkleiner.verklein(data) else { continue }
            let bijlage = Bijlage(soort: .foto, data: verkleind)
            context.insert(bijlage)
            bijlage.uitvoering = uitvoering
        }
        taak.volgendeDatum = planning.volgendeDatum(
            na: datum, intervalMaanden: inhoud.intervalMaanden, voorkeursMaanden: inhoud.voorkeursMaanden,
            dagInMaand: Planning.spreidingsdag(voor: taak.catalogusID ?? taak.id.uuidString))
        try? context.save()
        return uitvoering
    }

    func zetActief(_ actief: Bool, voor taak: Taak, nu: Date = Date(), context: ModelContext) {
        taak.isActief = actief
        // Een taak die weer aangaat en al lang te laat staat, komt niet meteen als achterstand terug.
        if actief, let datum = taak.volgendeDatum, planning.kalender.startOfDay(for: datum) < planning.kalender.startOfDay(for: nu) {
            taak.volgendeDatum = planning.kalender.startOfDay(for: nu)
        }
        try? context.save()
    }

    // MARK: Meldingen

    func herplanMeldingen(taken: [Taak]) async {
        let kandidaten = taken.map { $0.meldingKandidaat(titel: $0.inhoud(in: catalogus).titel) }
        await MeldingCentrum.gedeeld.herplan(kandidaten, kalender: planning.kalender)
    }
}

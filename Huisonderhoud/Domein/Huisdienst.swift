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

    // MARK: Meldingen

    func herplanMeldingen(taken: [Taak]) async {
        let kandidaten = taken.map { $0.meldingKandidaat(titel: $0.inhoud(in: catalogus).titel) }
        await MeldingCentrum.gedeeld.herplan(kandidaten, kalender: planning.kalender)
    }
}

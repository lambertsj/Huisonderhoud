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

    // MARK: Catalogus bijhouden

    /// Houdt de taken in lijn met de gebundelde catalogus, zonder iets weg te halen:
    /// - taken uit de catalogus bewaren de laatst bekende tekst en regels;
    /// - verdwijnt een taak uit de catalogus, dan wordt het een eigen taak met die tekst.
    /// Nieuwe taken worden hier nooit toegevoegd; dat gaat via `Voorstellen`.
    func synchroniseer(woning: Woning, context: ModelContext) {
        var gewijzigd = false
        for taak in woning.alleTaken {
            guard let id = taak.catalogusID else { continue }
            if let cat = catalogus.taak(met: id) {
                func zet<T: Equatable>(_ pad: ReferenceWritableKeyPath<Taak, T>, _ waarde: T) {
                    if taak[keyPath: pad] != waarde { taak[keyPath: pad] = waarde; gewijzigd = true }
                }
                zet(\.eigenTitel, cat.titel)
                zet(\.eigenUitleg, cat.uitleg)
                zet(\.eigenCategorie, cat.categorie)
                zet(\.eigenWaarschuwing, cat.waarschuwing)
                zet(\.eigenUitvoering, cat.uitvoering.rawValue)
                zet(\.eigenDuurMin, cat.duurMin)
                zet(\.laatsteIntervalMaanden, cat.intervalMaanden)
                zet(\.laatsteVoorkeursMaanden, cat.maanden)
            } else {
                taak.catalogusID = nil
                if taak.intervalMaanden == nil { taak.intervalMaanden = taak.laatsteIntervalMaanden }
                if taak.voorkeursMaanden.isEmpty { taak.voorkeursMaanden = taak.laatsteVoorkeursMaanden }
                gewijzigd = true
            }
        }
        if Voorstellen.bepaal(catalogus: catalogus, woning: woning).isLeeg, woning.catalogusVersie != catalogus.versie {
            woning.catalogusVersie = catalogus.versie
            gewijzigd = true
        }
        if gewijzigd { try? context.save() }
    }

    func voorstellen(voor woning: Woning) -> Voorstellen {
        Voorstellen.bepaal(catalogus: catalogus, woning: woning)
    }

    /// Past de keuze van de gebruiker toe.
    /// - Parameters:
    ///   - toevoegen: catalogus-id's die actief worden toegevoegd.
    ///   - uitgezet: catalogus-id's die wel een taak krijgen, maar uitgezet (zo blijven ze vindbaar).
    ///   - deactiveren: taken die uit gaan.
    ///   - behouden: taken die blijven staan; het voorstel komt niet terug.
    func pasVoorstellenToe(woning: Woning, toevoegen: Set<String>, uitgezet: Set<String>, deactiveren: [Taak],
                           behouden: [Taak], context: ModelContext, nu: Date = Date()) {
        let gekozen = toevoegen.union(uitgezet)
        if !gekozen.isEmpty {
            let items = EersteSchema.maak(catalogus: catalogus, kenmerken: woning.kenmerken, nu: nu, planning: planning)
            let datums = Dictionary(items.map { ($0.catalogusID, $0.volgendeDatum) }, uniquingKeysWith: { eerste, _ in eerste })
            for id in gekozen {
                guard let cat = catalogus.taak(met: id) else { continue }
                let taak = Taak(catalogus: cat, volgendeDatum: datums[id], woning: woning)
                taak.isActief = toevoegen.contains(id)
                context.insert(taak)
            }
        }
        for taak in deactiveren { taak.isActief = false }
        for taak in behouden {
            if let id = taak.catalogusID, !woning.negeerVoorstellen.contains(id) { woning.negeerVoorstellen.append(id) }
        }
        if voorstellen(voor: woning).isLeeg { woning.catalogusVersie = catalogus.versie }
        try? context.save()
    }

    // MARK: Eigen taken

    @discardableResult
    func maakEigenTaak(woning: Woning, titel: String, uitleg: String, categorie: String, intervalMaanden: Int?,
                       uitvoering: UitvoeringSoort, eersteDatum: Date, context: ModelContext) -> Taak {
        let taak = Taak(eigenTitel: titel.trimmingCharacters(in: .whitespacesAndNewlines),
                        eigenUitleg: uitleg.trimmingCharacters(in: .whitespacesAndNewlines),
                        eigenCategorie: categorie, intervalMaanden: intervalMaanden,
                        volgendeDatum: planning.kalender.startOfDay(for: eersteDatum), woning: woning)
        taak.eigenUitvoering = uitvoering.rawValue
        context.insert(taak)
        try? context.save()
        return taak
    }

    func verwijder(_ taak: Taak, context: ModelContext) {
        guard taak.catalogusID == nil else { return }
        context.delete(taak)
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

    /// Na het wijzigen of verwijderen van een uitvoering: de volgende datum volgt de laatste uitvoering.
    func herbereken(_ taak: Taak) {
        guard let laatste = taak.laatsteUitvoering else { return }
        let inhoud = taak.inhoud(in: catalogus)
        taak.volgendeDatum = planning.volgendeDatum(
            na: laatste.datum, intervalMaanden: inhoud.intervalMaanden, voorkeursMaanden: inhoud.voorkeursMaanden,
            dagInMaand: Planning.spreidingsdag(voor: taak.catalogusID ?? taak.id.uuidString))
    }

    /// Slaat een bewerkte uitvoering op. `fotos` is de gewenste eindstand: bestaande bijlagen die er
    /// niet meer in staan worden verwijderd, nieuwe (zonder bijlage) toegevoegd.
    func bewerk(_ uitvoering: Uitvoering, datum: Date, uitvoerder: Uitvoerder, uitvoerderNaam: String,
                notitie: String, fotos: [(Bijlage?, Data)], context: ModelContext) {
        uitvoering.datum = datum
        uitvoering.uitvoerder = uitvoerder
        let naam = uitvoerderNaam.trimmingCharacters(in: .whitespacesAndNewlines)
        uitvoering.uitvoerderNaam = (uitvoerder == .zelf || naam.isEmpty) ? nil : naam
        uitvoering.notitie = notitie.trimmingCharacters(in: .whitespacesAndNewlines)

        let behouden = Set(fotos.compactMap { $0.0?.id })
        for bijlage in uitvoering.alleBijlagen where bijlage.soort == .foto && !behouden.contains(bijlage.id) {
            context.delete(bijlage)
        }
        for (bijlage, data) in fotos where bijlage == nil {
            guard let verkleind = Fotoverkleiner.verklein(data) else { continue }
            let nieuw = Bijlage(soort: .foto, data: verkleind)
            context.insert(nieuw)
            nieuw.uitvoering = uitvoering
        }
        try? context.save()
        if let taak = uitvoering.taak { herbereken(taak) }
        try? context.save()
    }

    func verwijder(_ uitvoering: Uitvoering, context: ModelContext) {
        let taak = uitvoering.taak
        context.delete(uitvoering)
        try? context.save()
        if let taak { herbereken(taak) }
        try? context.save()
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

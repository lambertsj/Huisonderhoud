import Foundation

/// Wat de app voorstelt na een nieuwe dataset of een gewijzigd huisprofiel. Er wordt nooit
/// stilzwijgend iets toegevoegd, gedeactiveerd of verwijderd: de gebruiker kiest.
struct Voorstellen: Equatable {
    /// Catalogustaken die bij het huis horen maar nog geen taak hebben.
    var nieuw: [CatalogusTaak]
    /// Actieve catalogustaken waarvan het kenmerk is weggevallen.
    var uitzetten: [Taak]

    var isLeeg: Bool { nieuw.isEmpty && uitzetten.isEmpty }

    static func == (links: Voorstellen, rechts: Voorstellen) -> Bool {
        links.nieuw == rechts.nieuw && links.uitzetten.map(\.id) == rechts.uitzetten.map(\.id)
    }

    static func bepaal(catalogus: Catalogus, woning: Woning) -> Voorstellen {
        let aanwezig = Set(woning.alleTaken.compactMap(\.catalogusID))
        let genegeerd = Set(woning.negeerVoorstellen)
        let kenmerken = Set(woning.kenmerken)

        let nieuw = catalogus.taken(voorKenmerken: woning.kenmerken)
            .filter { !aanwezig.contains($0.id) && !genegeerd.contains($0.id) }

        let uitzetten = woning.alleTaken.filter { taak in
            guard taak.isActief, let id = taak.catalogusID, !genegeerd.contains(id),
                  let cat = catalogus.taak(met: id), !cat.voorwaarde.isEmpty else { return false }
            return kenmerken.isDisjoint(with: cat.voorwaarde)
        }
        .sorted { $0.eigenTitel < $1.eigenTitel }
        return Voorstellen(nieuw: nieuw, uitzetten: uitzetten)
    }
}

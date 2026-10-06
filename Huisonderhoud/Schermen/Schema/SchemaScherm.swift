import SwiftData
import SwiftUI

struct SchemaScherm: View {
    @Query private var woningen: [Woning]
    @Query(sort: \Taak.volgendeDatum) private var taken: [Taak]

    @Environment(Huisdienst.self) private var dienst

    @State private var zoek = ""
    @State private var pad = NavigationPath()

    var body: some View {
        let gevonden = taken.filter { zoekt($0) }
        let actief = gevonden.filter(\.isActief)
        let uit = gevonden.filter { !$0.isActief }
        let perCategorie = Dictionary(grouping: actief) { $0.inhoud(in: dienst.catalogus).categorie }
        let categorieen = Catalogus.categorieVolgorde.filter { perCategorie[$0] != nil }
            + perCategorie.keys.filter { !Catalogus.categorieVolgorde.contains($0) }.sorted()

        NavigationStack(path: $pad) {
            Scherm {
                kop

                if let woning = woningen.first {
                    VoorstelMelding(woning: woning)
                }

                Zoekveld(tekst: $zoek)

                if gevonden.isEmpty {
                    Text(zoek.isEmpty ? "Er staan nog geen taken in je schema. Voeg een eigen taak toe." : "Geen taken gevonden voor \u{201C}\(zoek)\u{201D}.")
                        .tekststijl(.uitleg)
                        .foregroundStyle(Color.inkMuted)
                }

                ForEach(categorieen, id: \.self) { categorie in
                    Groep(kop: categorie) {
                        BladRijen((perCategorie[categorie] ?? []).sorted { sorteer($0, $1) }) { TaakRijLink(taak: $0) }
                    }
                }

                if !uit.isEmpty {
                    Groep(kop: "Uitgezet") {
                        BladRijen(uit) { TaakRijLink(taak: $0) }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: Taak.self) { TaakDetailScherm(taak: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var kop: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Schermkop(titel: "Schema")
                Spacer(minLength: Ruimte.m)
                toevoegen
            }
            VStack(alignment: .leading, spacing: Ruimte.s) {
                Schermkop(titel: "Schema")
                toevoegen
            }
        }
    }

    @ViewBuilder private var toevoegen: some View {
        if let woning = woningen.first {
            NavigationLink {
                EigenTaakScherm(woning: woning, taak: nil)
            } label: {
                Text("Taak toevoegen").knopOpmaak(.tekst)
            }
        }
    }

    private func zoekt(_ taak: Taak) -> Bool {
        let term = zoek.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return true }
        let inhoud = taak.inhoud(in: dienst.catalogus)
        return inhoud.titel.localizedStandardContains(term) || inhoud.categorie.localizedStandardContains(term)
    }

    private func sorteer(_ a: Taak, _ b: Taak) -> Bool {
        switch (a.volgendeDatum, b.volgendeDatum) {
        case let (x?, y?): x == y ? a.inhoud(in: dienst.catalogus).titel < b.inhoud(in: dienst.catalogus).titel : x < y
        case (nil, _?): false
        case (_?, nil): true
        case (nil, nil): a.inhoud(in: dienst.catalogus).titel < b.inhoud(in: dienst.catalogus).titel
        }
    }
}

import SwiftData
import SwiftUI

struct BoekjeScherm: View {
    @Query(sort: \Uitvoering.datum, order: .reverse) private var uitvoeringen: [Uitvoering]
    @Query private var woningen: [Woning]
    @Query private var apparaten: [Apparaat]

    @Environment(Huisdienst.self) private var dienst

    @State private var dossier: DossierBestand?
    @State private var pad = NavigationPath()

    var body: some View {
        let jaren = Dictionary(grouping: uitvoeringen) { dienst.planning.kalender.component(.year, from: $0.datum) }
        let jaarLijst = jaren.keys.sorted(by: >)

        NavigationStack(path: $pad) {
            Scherm {
                Schermkop(titel: "Boekje", subregel: "Alles wat je aan je huis hebt gedaan")

                if uitvoeringen.isEmpty {
                    Text("Nog niets afgevinkt. Vink een klus af en hier verschijnt je eerste stempel.")
                        .tekststijl(.uitleg)
                        .foregroundStyle(Color.inkMuted)
                }

                ForEach(jaarLijst, id: \.self) { jaar in
                    Groep(kop: String(jaar)) {
                        BladRijen(jaren[jaar] ?? []) { uitvoering in
                            NavigationLink(value: uitvoering) {
                                UitvoeringRij(uitvoering: uitvoering)
                            }
                            .buttonStyle(RijKnopStijl())
                        }
                    }
                }

                if !uitvoeringen.isEmpty || !apparaten.isEmpty, let dossier {
                    ShareLink(item: dossier, preview: SharePreview("Onderhoudsdossier")) {
                        Text("Dossier als pdf bewaren").knopOpmaak(.secundair)
                    }
                }
            }
            .navigationDestination(for: Uitvoering.self) { UitvoeringScherm(uitvoering: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task(id: handtekening) { bouwDossier() }
    }

    /// Verandert zodra iets in het dossier verandert, zodat het pdf-item opnieuw wordt opgebouwd.
    private var handtekening: String {
        let u = uitvoeringen.map { "\($0.id)|\($0.datum.timeIntervalSince1970)|\($0.notitie)|\($0.uitvoerderRaw)|\($0.uitvoerderNaam ?? "")|\($0.alleBijlagen.count)|\($0.titelSnapshot)" }
        let a = apparaten.map { "\($0.id)|\($0.soort)|\($0.merk)|\($0.model)|\($0.serienummer)|\($0.aangeschaftOp?.timeIntervalSince1970 ?? 0)|\($0.garantieTot?.timeIntervalSince1970 ?? 0)|\($0.installateurNaam ?? "")" }
        let w = woningen.first.map { "\($0.naam)|\($0.bouwjaar ?? 0)|\($0.woningtype)" } ?? ""
        return (u + a + [w]).joined(separator: "\n")
    }

    private func bouwDossier() {
        guard let woning = woningen.first else { dossier = nil; return }
        dossier = DossierBestand(inhoud: DossierInhoud.maak(woning: woning, kalender: dienst.planning.kalender))
    }
}

/// Eén regel in het Boekje: de afgevinkte klus met zijn Stempel.
struct UitvoeringRij: View {
    let uitvoering: Uitvoering
    @Environment(Huisdienst.self) private var dienst

    var body: some View {
        let interval = uitvoering.taak?.inhoud(in: dienst.catalogus).intervalMaanden
        TaakRij(titel: uitvoering.titelSnapshot, status: .gedaan,
                wanneer: Wanneertekst.frequentie(intervalMaanden: interval),
                stempel: (uitvoering.datum, uitvoering.uitvoerder))
    }
}

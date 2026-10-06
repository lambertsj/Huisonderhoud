import SwiftData
import SwiftUI

/// Een melding op Schema en Huis: er zijn voorstellen voor jouw huis.
struct VoorstelMelding: View {
    let woning: Woning
    @Environment(Huisdienst.self) private var dienst

    var body: some View {
        // Opnieuw bepaald bij elke render; de woning en de taken zijn de bron.
        let voorstellen = dienst.voorstellen(voor: woning)
        if !voorstellen.isLeeg {
            Blad {
                NavigationLink {
                    VoorstellenScherm(woning: woning)
                } label: {
                    Lijstrij(titel: titel(voorstellen), waarde: "Bekijken")
                }
                .buttonStyle(RijKnopStijl())
            }
        }
    }

    private func titel(_ v: Voorstellen) -> String {
        var delen: [String] = []
        if !v.nieuw.isEmpty { delen.append(v.nieuw.count == 1 ? "1 nieuwe taak voor jouw huis" : "\(v.nieuw.count) nieuwe taken voor jouw huis") }
        if !v.uitzetten.isEmpty { delen.append(v.uitzetten.count == 1 ? "1 taak hoort niet meer bij jouw huis" : "\(v.uitzetten.count) taken horen niet meer bij jouw huis") }
        return delen.joined(separator: ". ")
    }
}

/// Nieuwe taken en taken die niet meer passen: de gebruiker kiest, er verandert niets vanzelf.
struct VoorstellenScherm: View {
    let woning: Woning

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var voorstellen: Voorstellen?
    @State private var nieuweKeuze: Set<String> = []
    @State private var uitzetKeuze: Set<UUID> = []

    var body: some View {
        Scherm {
            Schermkop(titel: "Voorstellen",
                      subregel: "Vink aan wat je wilt. Wat je niet aanvinkt, blijft zoals het is.",
                      subregelIsUitleg: true)

            if let voorstellen {
                if voorstellen.isLeeg {
                    Text("Niets meer te kiezen. Je schema is bij.")
                        .tekststijl(.uitleg)
                        .foregroundStyle(Color.inkMuted)
                }
                if !voorstellen.nieuw.isEmpty {
                    Groep(kop: "Nieuwe taken voor jouw huis") {
                        BladRijen(voorstellen.nieuw) { taak in
                            Toggle(isOn: Binding(get: { nieuweKeuze.contains(taak.id) }, set: { zet(taak.id, $0) })) {
                                VStack(alignment: .leading, spacing: Ruimte.xs) {
                                    Text(taak.titel)
                                    Text("\(Wanneertekst.frequentie(intervalMaanden: taak.intervalMaanden)), \(taak.uitvoering.label.lowercased())")
                                        .tekststijl(.klein)
                                        .foregroundStyle(Color.inkMuted)
                                }
                            }
                            .toggleStyle(.vinkje)
                        }
                    }
                    Text("Niet aangevinkte taken komen uitgezet in je schema te staan, zodat je ze later kunt aanzetten.")
                        .tekststijl(.klein)
                        .foregroundStyle(Color.inkMuted)
                }
                if !voorstellen.uitzetten.isEmpty {
                    Groep(kop: "Taken die niet meer passen") {
                        BladRijen(voorstellen.uitzetten) { taak in
                            Toggle(isOn: Binding(get: { uitzetKeuze.contains(taak.id) }, set: { zetUit(taak.id, $0) })) {
                                VStack(alignment: .leading, spacing: Ruimte.xs) {
                                    Text(taak.eigenTitel)
                                    Text("Aanvinken om uit te zetten")
                                        .tekststijl(.klein)
                                        .foregroundStyle(Color.inkMuted)
                                }
                            }
                            .toggleStyle(.vinkje)
                        }
                    }
                }
                if !voorstellen.isLeeg {
                    VStack(spacing: Ruimte.m) {
                        Button("Keuze opslaan") { pasToe(voorstellen) }
                            .buttonStyle(.primair)
                        Button("Nu niet") { dismiss() }
                            .buttonStyle(.tekst)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .task {
            let v = dienst.voorstellen(voor: woning)
            voorstellen = v
            nieuweKeuze = Set(v.nieuw.map(\.id))
            uitzetKeuze = Set(v.uitzetten.map(\.id))
        }
    }

    private func zet(_ id: String, _ aan: Bool) {
        if aan { nieuweKeuze.insert(id) } else { nieuweKeuze.remove(id) }
    }

    private func zetUit(_ id: UUID, _ aan: Bool) {
        if aan { uitzetKeuze.insert(id) } else { uitzetKeuze.remove(id) }
    }

    private func pasToe(_ v: Voorstellen) {
        let alleNieuw = Set(v.nieuw.map(\.id))
        dienst.pasVoorstellenToe(
            woning: woning,
            toevoegen: nieuweKeuze,
            uitgezet: alleNieuw.subtracting(nieuweKeuze),
            deactiveren: v.uitzetten.filter { uitzetKeuze.contains($0.id) },
            behouden: v.uitzetten.filter { !uitzetKeuze.contains($0.id) },
            context: context)
        let taken = woning.alleTaken
        Task { await dienst.herplanMeldingen(taken: taken) }
        dismiss()
    }
}

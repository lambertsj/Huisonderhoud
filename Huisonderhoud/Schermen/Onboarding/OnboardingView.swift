import SwiftData
import SwiftUI

/// Jouw huis → (optioneel) Wanneer deed je dit voor het laatst? → Herinneringen → Nu.
struct OnboardingView: View {
    /// Blijft true tot de laatste stap klaar is, ook al bestaat de woning dan al.
    @Binding var bezig: Bool

    @Environment(\.modelContext) private var context
    @Environment(Huisdienst.self) private var dienst

    private enum Stap { case kenmerken, laatsteKeer, meldingen }

    @State private var stap: Stap = .kenmerken
    @State private var woning: Woning?

    var body: some View {
        switch stap {
        case .kenmerken:
            JouwHuisScherm { keuzes in
                bezig = true
                let tags = Kenmerken.tags(voorKeuzes: keuzes)
                let nieuw = dienst.maakSchema(kenmerken: tags, context: context)
                woning = nieuw
                stap = dienst.zwareTaken(voor: nieuw).isEmpty ? .meldingen : .laatsteKeer
            }
        case .laatsteKeer:
            if let woning {
                LaatsteKeerScherm(taken: dienst.zwareTaken(voor: woning)) { antwoorden in
                    dienst.pasLaatsteKeerToe(antwoorden, woning: woning, context: context)
                    stap = .meldingen
                }
            }
        case .meldingen:
            MeldingenScherm {
                let taken = woning?.alleTaken ?? []
                await dienst.herplanMeldingen(taken: taken)
                bezig = false
            }
        }
    }
}

struct JouwHuisScherm: View {
    let schemaMaken: (Set<String>) -> Void
    @State private var keuzes: Set<String> = []

    var body: some View {
        Scherm {
            Schermkop(titel: "Jouw huis",
                      subregel: "Vink aan wat er bij je huis hoort. Daarmee stelt de app je onderhoudsschema samen. Alles blijft op je telefoon.",
                      subregelIsUitleg: true)

            ForEach(KenmerkGroep.allCases, id: \.self) { groep in
                Groep(kop: groep.titel) {
                    BladRijen(Kenmerken.keuzes(in: groep)) { keuze in
                        Toggle(keuze.titel, isOn: binding(voor: keuze.id))
                            .toggleStyle(.vinkje)
                    }
                }
            }

            Button("Schema maken") { schemaMaken(keuzes) }
                .buttonStyle(.primair)
        }
    }

    private func binding(voor id: String) -> Binding<Bool> {
        Binding(
            get: { keuzes.contains(id) },
            set: { aan in
                if aan { keuzes.insert(id) } else { keuzes.remove(id) }
            })
    }
}

struct LaatsteKeerScherm: View {
    let taken: [CatalogusTaak]
    let klaar: ([String: Date]) -> Void

    @State private var antwoorden: [String: Date] = [:]

    var body: some View {
        Scherm {
            Schermkop(titel: "Wanneer deed je dit voor het laatst?",
                      subregel: "Dit zijn klussen voor een vakman. Weet je het niet, dan plant de app ze in de komende drie maanden in. Je kunt dit overslaan.",
                      subregelIsUitleg: true)

            BladRijen(taken) { taak in
                LaatsteKeerRij(titel: taak.titel, datum: binding(voor: taak.id))
            }

            VStack(spacing: Ruimte.m) {
                Button("Opslaan") { klaar(antwoorden) }
                    .buttonStyle(.primair)
                Button("Overslaan") { klaar([:]) }
                    .buttonStyle(.tekst)
            }
        }
    }

    private func binding(voor id: String) -> Binding<Date?> {
        Binding(get: { antwoorden[id] }, set: { antwoorden[id] = $0 })
    }
}

private struct LaatsteKeerRij: View {
    let titel: String
    @Binding var datum: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.s) {
            Text(titel)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
            if let waarde = datum {
                HStack {
                    DatePicker("Laatste keer: \(titel)", selection: Binding(get: { waarde }, set: { datum = $0 }),
                               in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                    Spacer(minLength: Ruimte.m)
                    Button("Weet ik niet") { datum = nil }
                        .buttonStyle(.tekst)
                }
            } else {
                HStack {
                    Text("Weet ik niet")
                        .tekststijl(.klein)
                        .foregroundStyle(Color.inkMuted)
                    Spacer(minLength: Ruimte.m)
                    Button("Datum kiezen") { datum = Calendar.current.date(byAdding: .year, value: -1, to: Date()) }
                        .buttonStyle(.tekst)
                        .accessibilityLabel("Datum kiezen voor \(titel)")
                }
            }
        }
        .padding(.horizontal, Ruimte.l)
        .padding(.vertical, Ruimte.m)
        .frame(maxWidth: .infinity, minHeight: Ruimte.rijMinHoogte, alignment: .leading)
    }
}

struct MeldingenScherm: View {
    let klaar: () async -> Void
    @State private var bezig = false

    var body: some View {
        Scherm {
            Schermkop(titel: "Herinneringen",
                      subregel: "Wil je een herinnering als een klus aan de beurt is? Je krijgt dan om 9 uur een melding op de dag dat de klus aan de beurt is. Geen teller op het pictogram, geen reclame. Je kunt dit later aanpassen bij Huis.",
                      subregelIsUitleg: true)

            VStack(spacing: Ruimte.m) {
                Button("Herinneringen aanzetten") {
                    Task {
                        bezig = true
                        _ = await MeldingCentrum.gedeeld.toestemmingVragen()
                        await klaar()
                    }
                }
                .buttonStyle(.primair)
                Button("Nu niet") {
                    Task {
                        bezig = true
                        await klaar()
                    }
                }
                .buttonStyle(.tekst)
            }
            .disabled(bezig)
        }
    }
}

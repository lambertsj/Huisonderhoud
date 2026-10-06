import SwiftData
import SwiftUI

/// Een rij die naar het taakdetail leidt. Gedeeld door Nu en Schema.
struct TaakRijLink: View {
    let taak: Taak

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.nu) private var nu

    var body: some View {
        let inhoud = taak.inhoud(in: dienst.catalogus)
        let tijd = nu()
        let status = taak.status(in: dienst.catalogus, planning: dienst.planning, nu: tijd)
        let wanneer = taak.isActief
            ? Wanneertekst.maak(status: status, datum: taak.volgendeDatum, voorkeursMaanden: inhoud.voorkeursMaanden,
                                nu: tijd, kalender: dienst.planning.kalender)
            : "Uitgezet"
        NavigationLink(value: taak) {
            TaakRij(
                titel: inhoud.titel,
                status: taak.isActief ? status : .later,
                wanneer: wanneer,
                uitvoering: inhoud.uitvoering,
                duur: inhoud.duurMin)
        }
        .buttonStyle(RijKnopStijl())
    }
}

struct NuScherm: View {
    @Query(filter: #Predicate<Taak> { $0.isActief && $0.volgendeDatum != nil },
           sort: \Taak.volgendeDatum) private var taken: [Taak]

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.nu) private var nu
    @State private var pad = NavigationPath()

    var body: some View {
        let tijd = nu()
        let perStatus = Dictionary(grouping: taken) { $0.status(in: dienst.catalogus, planning: dienst.planning, nu: tijd) }
        let teLaat = perStatus[.telaat] ?? []
        let dezeMaand = perStatus[.nu] ?? []
        let later = perStatus[.later] ?? []

        NavigationStack(path: $pad) {
            Scherm {
                Schermkop(titel: "Nu aan de beurt",
                          subregel: Datumopmaak.dagMaand(tijd, kalender: dienst.planning.kalender))

                if teLaat.isEmpty && dezeMaand.isEmpty {
                    Text("Niets aan de beurt. Je huis is bij.")
                        .tekststijl(.uitleg)
                        .foregroundStyle(Color.inkMuted)
                }
                groep("Te laat", teLaat)
                groep("Deze maand", dezeMaand)
                groep("Later", later)
            }
            .navigationDestination(for: Taak.self) { TaakDetailScherm(taak: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        #if DEBUG
        .task {
            // Voor screenshots: `-open-eerste-waarschuwing` opent de eerste taak met een waarschuwing.
            // `-open-taak <catalogus-id>` opent die taak.
            let args = CommandLine.arguments
            if let i = args.firstIndex(of: "-open-taak"), i + 1 < args.count,
               let taak = taken.first(where: { $0.catalogusID == args[i + 1] }) {
                pad.append(taak)
            } else if args.contains("-open-eerste-waarschuwing"),
                      let taak = taken.first(where: { $0.eigenWaarschuwing != nil }) {
                pad.append(taak)
            }
        }
        #endif
    }

    @ViewBuilder private func groep(_ kop: String, _ taken: [Taak]) -> some View {
        if !taken.isEmpty {
            Groep(kop: kop) {
                BladRijen(taken) { TaakRijLink(taak: $0) }
            }
        }
    }
}

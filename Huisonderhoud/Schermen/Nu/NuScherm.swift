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
        NavigationLink(value: taak) {
            TaakRij(
                titel: inhoud.titel,
                status: status,
                wanneer: Wanneertekst.maak(status: status, datum: taak.volgendeDatum,
                                           voorkeursMaanden: inhoud.voorkeursMaanden, nu: tijd,
                                           kalender: dienst.planning.kalender),
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

    var body: some View {
        let tijd = nu()
        let perStatus = Dictionary(grouping: taken) { $0.status(in: dienst.catalogus, planning: dienst.planning, nu: tijd) }
        let teLaat = perStatus[.telaat] ?? []
        let dezeMaand = perStatus[.nu] ?? []
        let later = perStatus[.later] ?? []

        NavigationStack {
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
    }

    @ViewBuilder private func groep(_ kop: String, _ taken: [Taak]) -> some View {
        if !taken.isEmpty {
            Groep(kop: kop) {
                BladRijen(taken) { TaakRijLink(taak: $0) }
            }
        }
    }
}

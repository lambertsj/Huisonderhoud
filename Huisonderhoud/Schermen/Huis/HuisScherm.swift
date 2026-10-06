import SwiftData
import SwiftUI
import UserNotifications

struct HuisScherm: View {
    @Query private var woningen: [Woning]
    @Query(sort: \Apparaat.soort) private var apparaten: [Apparaat]
    @Query private var alleTaken: [Taak]

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    @State private var herinneringenAan = MeldingCentrum.gedeeld.herinneringenAan
    @State private var autorisatie: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Scherm {
                Schermkop(titel: "Huis")

                if let woning = woningen.first {
                    VoorstelMelding(woning: woning)

                    Groep(kop: "Woning") {
                        NavigationLink {
                            ProfielScherm(woning: woning)
                        } label: {
                            Lijstrij(titel: woning.naam.isEmpty ? "Mijn huis" : woning.naam,
                                     waarde: profielregel(woning))
                        }
                        .buttonStyle(RijKnopStijl())
                        Haarlijn()
                        NavigationLink {
                            ProfielScherm(woning: woning)
                        } label: {
                            Lijstrij(titel: "Kenmerken", waarde: kenmerkenregel(woning))
                        }
                        .buttonStyle(RijKnopStijl())
                    }

                    Groep(kop: "Apparaten") {
                        ForEach(Array(apparaten.enumerated()), id: \.element.id) { index, apparaat in
                            if index > 0 { Haarlijn() }
                            NavigationLink {
                                ApparaatScherm(woning: woning, apparaat: apparaat)
                            } label: {
                                Lijstrij(titel: titel(apparaat), waarde: apparaat.garantieTot.map { "Garantie tot \(Datumopmaak.kort($0))" })
                            }
                            .buttonStyle(RijKnopStijl())
                        }
                        if apparaten.isEmpty {
                            Text("Nog geen apparaten. Voeg bijvoorbeeld je cv-ketel toe, met merk, serienummer en een foto van het typeplaatje.")
                                .tekststijl(.body)
                                .foregroundStyle(Color.inkMuted)
                                .padding(Ruimte.l)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Haarlijn()
                        NavigationLink {
                            ApparaatScherm(woning: woning, apparaat: nil)
                        } label: {
                            Text("Apparaat toevoegen")
                                .tekststijl(.taak)
                                .foregroundStyle(Color.brand)
                                .padding(.horizontal, Ruimte.l)
                                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(RijKnopStijl())
                    }
                }

                herinneringen

                GegevensGroep(woningnaam: woningen.first?.naam ?? "")

                OverGroep()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { autorisatie = await MeldingCentrum.gedeeld.autorisatiestatus() }
    }

    // MARK: Herinneringen

    private var herinneringen: some View {
        Groep(kop: "Herinneringen") {
            Toggle(isOn: Binding(get: { herinneringenAan }, set: { zetHerinneringen($0) })) {
                VStack(alignment: .leading, spacing: Ruimte.xs) {
                    Text("Herinnering als een klus aan de beurt is")
                        .tekststijl(.body)
                        .foregroundStyle(Color.ink)
                    Text("Om 9 uur op de dag zelf. Geen teller op het pictogram.")
                        .tekststijl(.klein)
                        .foregroundStyle(Color.inkMuted)
                }
            }
            .tint(Color.brand)
            .padding(.horizontal, Ruimte.l)
            .padding(.vertical, Ruimte.m)
            .frame(minHeight: 56)

            if autorisatie == .denied {
                Haarlijn()
                VStack(alignment: .leading, spacing: Ruimte.s) {
                    Text("Meldingen staan voor Huisonderhoud uit in Instellingen. Zet ze daar aan om herinneringen te krijgen.")
                        .tekststijl(.klein)
                        .foregroundStyle(Color.inkMuted)
                    Button("Instellingen openen") {
                        if let url = URL(string: "app-settings:") { openURL(url) }
                    }
                    .buttonStyle(.tekst)
                }
                .padding(Ruimte.l)
            }
        }
    }

    private func zetHerinneringen(_ aan: Bool) {
        herinneringenAan = aan
        Task {
            if aan {
                autorisatie = await MeldingCentrum.gedeeld.autorisatiestatus()
                if autorisatie == .notDetermined {
                    herinneringenAan = await MeldingCentrum.gedeeld.toestemmingVragen()
                } else {
                    MeldingCentrum.gedeeld.herinneringenAan = autorisatie == .authorized
                    herinneringenAan = autorisatie == .authorized
                }
                autorisatie = await MeldingCentrum.gedeeld.autorisatiestatus()
            } else {
                MeldingCentrum.gedeeld.herinneringenAan = false
            }
            await dienst.herplanMeldingen(taken: alleTaken)
        }
    }

    // MARK: Teksten

    private func profielregel(_ woning: Woning) -> String? {
        var delen: [String] = []
        if !woning.woningtype.isEmpty { delen.append(woning.woningtype) }
        if let bouwjaar = woning.bouwjaar { delen.append("bouwjaar \(bouwjaar)") }
        return delen.isEmpty ? "Naam, bouwjaar en type" : delen.joined(separator: ", ")
    }

    private func kenmerkenregel(_ woning: Woning) -> String {
        woning.kenmerken.isEmpty ? "Geen" : "\(woning.kenmerken.count) gekozen"
    }

    private func titel(_ apparaat: Apparaat) -> String {
        let delen = [apparaat.soort, apparaat.merk].filter { !$0.isEmpty }
        return delen.isEmpty ? "Apparaat" : delen.joined(separator: ", ")
    }
}

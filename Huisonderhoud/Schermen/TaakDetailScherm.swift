import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct TaakDetailScherm: View {
    let taak: Taak

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.nu) private var nu
    @Environment(\.accessibilityReduceMotion) private var verminderBeweging

    @State private var notitie = ""
    @State private var uitvoerder: Uitvoerder?
    @State private var fotos: [Data] = []
    @State private var gekozenFotos: [PhotosPickerItem] = []
    @State private var afgevinkt: Uitvoering?

    var body: some View {
        let inhoud = taak.inhoud(in: dienst.catalogus)
        let tijd = nu()
        let status = taak.status(in: dienst.catalogus, planning: dienst.planning, nu: tijd)
        let wanneer = Wanneertekst.maak(status: status, datum: taak.volgendeDatum, voorkeursMaanden: inhoud.voorkeursMaanden,
                                        nu: tijd, kalender: dienst.planning.kalender)

        Scherm {
            VStack(alignment: .leading, spacing: Ruimte.s) {
                Text(inhoud.titel)
                    .tekststijl(.titelGroot)
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(Wanneertekst.taakregel(status: status, wanneer: wanneer, uitvoering: inhoud.uitvoering,
                                            duurMin: inhoud.duurMin, heeftDatum: taak.volgendeDatum != nil))
                    .tekststijl(.klein)
                    .foregroundStyle(Color.inkMuted)
                if !taak.isActief {
                    Text("Deze taak staat uit. Je krijgt er geen herinnering voor.")
                        .tekststijl(.klein)
                        .foregroundStyle(Color.inkMuted)
                }
            }

            if !inhoud.uitleg.isEmpty {
                Text(inhoud.uitleg)
                    .tekststijl(.uitleg)
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: 560, alignment: .leading)
            }

            if let waarschuwing = inhoud.waarschuwing {
                Waarschuwing(tekst: waarschuwing)
            }

            if let vorige = taak.laatsteUitvoering {
                VorigeKeer(uitvoering: vorige)
            }

            if let afgevinkt {
                HStack {
                    Spacer()
                    Stempel(datum: afgevinkt.datum, door: afgevinkt.uitvoerder, landt: true)
                    Spacer()
                }
                .padding(.vertical, Ruimte.xl)
            } else if taak.isActief {
                invoer(inhoud: inhoud)
            } else {
                Button("Taak aanzetten") {
                    dienst.zetActief(true, voor: taak, nu: nu(), context: context)
                    herplan()
                }
                .buttonStyle(.primair)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { menu }
        }
        .onChange(of: gekozenFotos) { _, nieuw in laadFotos(nieuw) }
    }

    // MARK: Onderdelen

    @ViewBuilder private func invoer(inhoud: TaakInhoud) -> some View {
        VStack(alignment: .leading, spacing: Ruimte.l) {
            Invoerveld(label: "Notitie", placeholder: "Wat viel je op?", tekst: $notitie, regels: 2...8)

            Keuzerij(label: "Wie deed het?",
                     opties: [(Uitvoerder.zelf, "Zelf"), (Uitvoerder.vakman, "Vakman")],
                     keuze: Binding(get: { uitvoerder ?? dienst.standaardUitvoerder(voor: taak) },
                                    set: { uitvoerder = $0 }))

            if !fotos.isEmpty {
                Fotostrook(fotos: fotos) { index in fotos.remove(at: index) }
            }

            PhotosPicker(selection: $gekozenFotos, maxSelectionCount: 5, matching: .images) {
                Text("Foto toevoegen").knopOpmaak(.secundair)
            }

            Button("Afvinken") { vinkAf() }
                .buttonStyle(.primair)
        }
    }

    private var menu: some View {
        Menu {
            if taak.isActief {
                Button("Taak uitzetten") {
                    dienst.zetActief(false, voor: taak, context: context)
                    herplan()
                    dismiss()
                }
            } else {
                Button("Taak aanzetten") {
                    dienst.zetActief(true, voor: taak, nu: nu(), context: context)
                    herplan()
                }
            }
            Button(taak.herinneringAan ? "Herinnering uitzetten" : "Herinnering aanzetten") {
                taak.herinneringAan.toggle()
                try? context.save()
                herplan()
            }
        } label: {
            Text("Meer")
                .tekststijl(.taak)
                .foregroundStyle(Color.brand)
                .frame(minWidth: Ruimte.aanraakminimum, minHeight: Ruimte.aanraakminimum)
        }
        .accessibilityLabel("Meer acties voor deze taak")
    }

    // MARK: Handelingen

    private func vinkAf() {
        let uitvoering = dienst.vinkAf(taak, datum: nu(), uitvoerder: uitvoerder ?? dienst.standaardUitvoerder(voor: taak),
                                       notitie: notitie, fotos: fotos, context: context)
        afgevinkt = uitvoering
        herplan()
        UIAccessibility.post(notification: .announcement, argument: "Afgevinkt")
        Task {
            try? await Task.sleep(for: .milliseconds(verminderBeweging ? 700 : 1100))
            dismiss()
        }
    }

    private func herplan() {
        let taken = taak.woning?.alleTaken ?? [taak]
        Task { await dienst.herplanMeldingen(taken: taken) }
    }

    private func laadFotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let verkleind = Fotoverkleiner.verklein(data) {
                    fotos.append(verkleind)
                }
            }
            gekozenFotos = []
        }
    }
}

/// "Vorige keer" met de Stempel van de laatste uitvoering.
private struct VorigeKeer: View {
    let uitvoering: Uitvoering

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Blad {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Ruimte.m) { tekst; stempel }
                } else {
                    HStack(spacing: Ruimte.l) { tekst; Spacer(minLength: 0); stempel }
                }
            }
            .padding(.horizontal, Ruimte.l)
            .padding(.vertical, Ruimte.m)
            .frame(maxWidth: .infinity, minHeight: Ruimte.rijMinHoogte, alignment: .leading)
        }
    }

    private var tekst: some View {
        VStack(alignment: .leading, spacing: Ruimte.xs) {
            Text("Vorige keer")
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
            if !uitvoering.notitie.isEmpty {
                Text(uitvoering.notitie)
                    .tekststijl(.klein)
                    .foregroundStyle(Color.inkMuted)
                    .lineLimit(3)
            }
        }
    }

    private var stempel: some View {
        Stempel(datum: uitvoering.datum, door: uitvoering.uitvoerder)
            .padding(.trailing, Ruimte.xs)
    }
}

#if DEBUG
#Preview("Taakdetail") {
    NavigationStack {
        TaakDetailPreview()
    }
    .environment(Voorbeeld.dienst)
    .modelContainer(Voorbeeld.container())
}

#Preview("Taakdetail, donker, grootste tekst") {
    NavigationStack {
        TaakDetailPreview()
    }
    .environment(Voorbeeld.dienst)
    .modelContainer(Voorbeeld.container())
    .preferredColorScheme(.dark)
    .dynamicTypeSize(.accessibility5)
}

private struct TaakDetailPreview: View {
    @Query(sort: \Taak.volgendeDatum) private var taken: [Taak]

    var body: some View {
        if let taak = taken.first(where: { $0.eigenWaarschuwing != nil }) {
            TaakDetailScherm(taak: taak)
        }
    }
}
#endif

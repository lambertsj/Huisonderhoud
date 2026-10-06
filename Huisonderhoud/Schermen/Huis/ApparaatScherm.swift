import PhotosUI
import SwiftData
import SwiftUI

/// Apparaat toevoegen of bewerken, met een foto van het typeplaatje.
struct ApparaatScherm: View {
    let woning: Woning
    let apparaat: Apparaat?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private struct FotoItem: Identifiable {
        let id = UUID()
        var bijlage: Bijlage?
        var data: Data
    }

    @State private var soort: String
    @State private var merk: String
    @State private var model: String
    @State private var serienummer: String
    @State private var aangeschaft: Date?
    @State private var garantieTot: Date?
    @State private var installateur: String
    @State private var notitie: String
    @State private var fotos: [FotoItem]
    @State private var gekozenFotos: [PhotosPickerItem] = []
    @State private var verwijderen = false

    init(woning: Woning, apparaat: Apparaat?) {
        self.woning = woning
        self.apparaat = apparaat
        _soort = State(initialValue: apparaat?.soort ?? "")
        _merk = State(initialValue: apparaat?.merk ?? "")
        _model = State(initialValue: apparaat?.model ?? "")
        _serienummer = State(initialValue: apparaat?.serienummer ?? "")
        _aangeschaft = State(initialValue: apparaat?.aangeschaftOp)
        _garantieTot = State(initialValue: apparaat?.garantieTot)
        _installateur = State(initialValue: apparaat?.installateurNaam ?? "")
        _notitie = State(initialValue: apparaat?.notitie ?? "")
        _fotos = State(initialValue: (apparaat?.alleBijlagen ?? [])
            .filter { $0.soort == .foto }
            .sorted { $0.aangemaakt < $1.aangemaakt }
            .compactMap { b in b.data.map { FotoItem(bijlage: b, data: $0) } })
    }

    var body: some View {
        Scherm {
            Schermkop(titel: apparaat == nil ? "Nieuw apparaat" : "Apparaat")

            VStack(alignment: .leading, spacing: Ruimte.l) {
                Invoerveld(label: "Soort", placeholder: "Bijvoorbeeld cv-ketel", tekst: $soort)
                Invoerveld(label: "Merk", placeholder: "Merk", tekst: $merk)
                Invoerveld(label: "Model", placeholder: "Model", tekst: $model)
                Invoerveld(label: "Serienummer", placeholder: "Staat op het typeplaatje", tekst: $serienummer)
                OptioneleDatum(label: "Aangeschaft op", datum: $aangeschaft)
                OptioneleDatum(label: "Garantie tot", datum: $garantieTot)
                Invoerveld(label: "Installateur", placeholder: "Naam of bedrijf", tekst: $installateur)
                Invoerveld(label: "Notitie", placeholder: "Bijvoorbeeld waar het staat", tekst: $notitie, regels: 2...6)

                if !fotos.isEmpty {
                    Fotostrook(fotos: fotos.map(\.data)) { index in fotos.remove(at: index) }
                }
                PhotosPicker(selection: $gekozenFotos, maxSelectionCount: 3, matching: .images) {
                    Text("Foto van het typeplaatje toevoegen").knopOpmaak(.secundair)
                }

                Button("Opslaan") { bewaar() }
                    .buttonStyle(.primair)
                if apparaat != nil {
                    Button("Verwijderen") { verwijderen = true }
                        .buttonStyle(.tekst)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .onChange(of: gekozenFotos) { _, nieuw in laadFotos(nieuw) }
        .confirmationDialog("Dit apparaat verwijderen?", isPresented: $verwijderen, titleVisibility: .visible) {
            Button("Verwijderen", role: .destructive) {
                if let apparaat { context.delete(apparaat); try? context.save() }
                dismiss()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("De gegevens en foto's van dit apparaat verdwijnen. Taken en het Boekje blijven bestaan.")
        }
    }

    private func bewaar() {
        let doel = apparaat ?? Apparaat(woning: woning)
        if apparaat == nil { context.insert(doel); doel.woning = woning }
        doel.soort = soort.trimmingCharacters(in: .whitespacesAndNewlines)
        doel.merk = merk.trimmingCharacters(in: .whitespacesAndNewlines)
        doel.model = model.trimmingCharacters(in: .whitespacesAndNewlines)
        doel.serienummer = serienummer.trimmingCharacters(in: .whitespacesAndNewlines)
        doel.aangeschaftOp = aangeschaft
        doel.garantieTot = garantieTot
        let naam = installateur.trimmingCharacters(in: .whitespacesAndNewlines)
        doel.installateurNaam = naam.isEmpty ? nil : naam
        doel.notitie = notitie.trimmingCharacters(in: .whitespacesAndNewlines)

        let behouden = Set(fotos.compactMap { $0.bijlage?.id })
        for bijlage in doel.alleBijlagen where !behouden.contains(bijlage.id) { context.delete(bijlage) }
        for item in fotos where item.bijlage == nil {
            let nieuw = Bijlage(soort: .foto, titel: "Typeplaatje", data: item.data)
            context.insert(nieuw)
            nieuw.apparaat = doel
        }
        try? context.save()
        dismiss()
    }

    private func laadFotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let verkleind = Fotoverkleiner.verklein(data) {
                    fotos.append(FotoItem(bijlage: nil, data: verkleind))
                }
            }
            gekozenFotos = []
        }
    }
}

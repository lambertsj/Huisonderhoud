import PhotosUI
import SwiftData
import SwiftUI

/// Eén uitvoering uit het Boekje: bekijken, bewerken en verwijderen.
struct UitvoeringScherm: View {
    let uitvoering: Uitvoering

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private struct FotoItem: Identifiable {
        let id = UUID()
        var bijlage: Bijlage?
        var data: Data
    }

    @State private var datum: Date
    @State private var uitvoerder: Uitvoerder
    @State private var naam: String
    @State private var notitie: String
    @State private var fotos: [FotoItem]
    @State private var gekozenFotos: [PhotosPickerItem] = []
    @State private var verwijderen = false

    init(uitvoering: Uitvoering) {
        self.uitvoering = uitvoering
        _datum = State(initialValue: uitvoering.datum)
        _uitvoerder = State(initialValue: uitvoering.uitvoerder)
        _naam = State(initialValue: uitvoering.uitvoerderNaam ?? "")
        _notitie = State(initialValue: uitvoering.notitie)
        _fotos = State(initialValue: uitvoering.alleBijlagen
            .filter { $0.soort == .foto }
            .sorted { $0.aangemaakt < $1.aangemaakt }
            .compactMap { b in b.data.map { FotoItem(bijlage: b, data: $0) } })
    }

    var body: some View {
        Scherm {
            Schermkop(titel: uitvoering.titelSnapshot, subregel: uitvoering.categorieSnapshot)

            HStack {
                Stempel(datum: datum, door: uitvoerder)
                Spacer()
            }

            VStack(alignment: .leading, spacing: Ruimte.l) {
                VStack(alignment: .leading, spacing: Ruimte.s) {
                    Text("Datum").tekststijl(.taak).foregroundStyle(Color.ink)
                    DatePicker("Datum", selection: $datum, in: ...Date(), displayedComponents: .date)
                        .labelsHidden()
                        .frame(minHeight: Ruimte.aanraakminimum, alignment: .leading)
                }

                Keuzerij(label: "Wie deed het?",
                         opties: [(Uitvoerder.zelf, "Zelf"), (Uitvoerder.vakman, "Vakman"), (Uitvoerder.anders, "Anders")],
                         keuze: $uitvoerder)

                if uitvoerder != .zelf {
                    Invoerveld(label: "Naam", placeholder: "Naam of bedrijf", tekst: $naam)
                }

                Invoerveld(label: "Notitie", placeholder: "Wat viel je op?", tekst: $notitie, regels: 2...8)

                if !fotos.isEmpty {
                    Fotostrook(fotos: fotos.map(\.data)) { index in fotos.remove(at: index) }
                }

                PhotosPicker(selection: $gekozenFotos, maxSelectionCount: 5, matching: .images) {
                    Text("Foto toevoegen").knopOpmaak(.secundair)
                }

                Button("Opslaan") { bewaar() }
                    .buttonStyle(.primair)
                Button("Verwijderen") { verwijderen = true }
                    .buttonStyle(.tekst)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .onChange(of: gekozenFotos) { _, nieuw in laadFotos(nieuw) }
        .confirmationDialog("Deze klus uit het Boekje verwijderen?", isPresented: $verwijderen, titleVisibility: .visible) {
            Button("Verwijderen", role: .destructive) {
                dienst.verwijder(uitvoering, context: context)
                dismiss()
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("De stempel en de foto's verdwijnen uit het Boekje. Dit kan niet ongedaan worden gemaakt.")
        }
    }

    private func bewaar() {
        dienst.bewerk(uitvoering, datum: datum, uitvoerder: uitvoerder, uitvoerderNaam: naam, notitie: notitie,
                      fotos: fotos.map { ($0.bijlage, $0.data) }, context: context)
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

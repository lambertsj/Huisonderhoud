import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Exporteren en importeren van je eigen gegevens.
struct GegevensGroep: View {
    let woningnaam: String

    @Environment(\.modelContext) private var context
    @Environment(Huisdienst.self) private var dienst
    @Query private var alleTaken: [Taak]

    @State private var kiezen = false
    @State private var wachtend: (export: Export, analyse: Import.Analyse)?
    @State private var bevestigen = false
    @State private var melding: String?

    var body: some View {
        Groep(kop: "Gegevens") {
            VStack(alignment: .leading, spacing: Ruimte.m) {
                Text("Je gegevens staan alleen op je telefoon. Met een export bewaar je ze zelf, bijvoorbeeld in Bestanden, of neem je ze mee naar een nieuwe telefoon.")
                    .tekststijl(.klein)
                    .foregroundStyle(Color.inkMuted)

                ShareLink(item: ExportBestand(container: context.container, catalogusVersie: dienst.catalogus.versie),
                          preview: SharePreview("Huisonderhoud gegevens")) {
                    Text("Gegevens exporteren").knopOpmaak(.secundair)
                }
                Button("Gegevens importeren") { kiezen = true }
                    .buttonStyle(.secundair)

                if let melding {
                    Text(melding)
                        .tekststijl(.body)
                        .foregroundStyle(Color.ink)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .padding(Ruimte.l)
        }
        .fileImporter(isPresented: $kiezen, allowedContentTypes: [.json]) { resultaat in
            lees(resultaat)
        }
        .confirmationDialog("Een deel van dit bestand staat al in je app", isPresented: $bevestigen, titleVisibility: .visible) {
            Button("Overschrijven") { voerUit(.overschrijven) }
            Button("Overslaan") { voerUit(.overslaan) }
            Button("Annuleren", role: .cancel) { wachtend = nil }
        } message: {
            if let wachtend {
                Text("\(wachtend.analyse.bestaand) van \(wachtend.analyse.totaal) onderdelen bestaan al. Overschrijven vervangt ze door de versie uit het bestand. Overslaan laat ze zoals ze zijn.")
            }
        }
    }

    private func lees(_ resultaat: Result<URL, Error>) {
        melding = nil
        guard case .success(let url) = resultaat else {
            melding = "Het bestand kon niet worden geopend."
            return
        }
        let toegang = url.startAccessingSecurityScopedResource()
        defer { if toegang { url.stopAccessingSecurityScopedResource() } }
        do {
            let export = try Export.lees(Data(contentsOf: url))
            let analyse = try Import.analyseer(export, context: context)
            if analyse.bestaand > 0 {
                wachtend = (export, analyse)
                bevestigen = true
            } else {
                wachtend = (export, analyse)
                voerUit(.overslaan)
            }
        } catch {
            melding = (error as? LocalizedError)?.errorDescription ?? "Het bestand kon niet worden gelezen."
        }
    }

    private func voerUit(_ bestaande: Import.Bestaande) {
        guard let export = wachtend?.export else { return }
        wachtend = nil
        do {
            let r = try Import.voerUit(export, context: context, bestaande: bestaande)
            var delen = ["\(r.toegevoegd) toegevoegd"]
            if r.overschreven > 0 { delen.append("\(r.overschreven) overschreven") }
            if r.overgeslagen > 0 { delen.append("\(r.overgeslagen) overgeslagen") }
            melding = delen.joined(separator: ", ") + "."
            let taken = (try? context.fetch(FetchDescriptor<Taak>())) ?? alleTaken
            Task { await dienst.herplanMeldingen(taken: taken) }
        } catch {
            melding = "Importeren is niet gelukt. Er is niets gewijzigd dat je kwijt kunt raken."
        }
    }
}

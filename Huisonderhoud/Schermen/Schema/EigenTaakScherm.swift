import SwiftData
import SwiftUI

/// Eigen taak toevoegen of bewerken: titel, uitleg, interval, uitvoering, categorie.
struct EigenTaakScherm: View {
    let woning: Woning
    let taak: Taak?

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var titel: String
    @State private var uitleg: String
    @State private var categorie: String
    @State private var interval: Int
    @State private var uitvoering: UitvoeringSoort
    @State private var eerste: Date?

    /// 0 betekent: niet herhalen.
    private static let intervallen = [1, 2, 3, 6, 12, 24, 60, 0]

    init(woning: Woning, taak: Taak?) {
        self.woning = woning
        self.taak = taak
        _titel = State(initialValue: taak?.eigenTitel ?? "")
        _uitleg = State(initialValue: taak?.eigenUitleg ?? "")
        _categorie = State(initialValue: taak.flatMap { $0.eigenCategorie.isEmpty ? nil : $0.eigenCategorie } ?? "Seizoen")
        _interval = State(initialValue: taak?.intervalMaanden ?? (taak == nil ? 12 : 0))
        _uitvoering = State(initialValue: taak.flatMap { UitvoeringSoort(rawValue: $0.eigenUitvoering) } ?? .zelf)
        _eerste = State(initialValue: taak?.volgendeDatum ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()))
    }

    var body: some View {
        Scherm {
            Schermkop(titel: taak == nil ? "Nieuwe taak" : "Taak bewerken")

            VStack(alignment: .leading, spacing: Ruimte.l) {
                Invoerveld(label: "Titel", placeholder: "Bijvoorbeeld dakkapel schoonmaken", tekst: $titel)
                Invoerveld(label: "Uitleg", placeholder: "Wat moet er gebeuren?", tekst: $uitleg, regels: 2...8)
                Keuzemenu(label: "Categorie",
                          opties: Catalogus.categorieVolgorde.map { ($0, $0) },
                          keuze: $categorie)
                Keuzemenu(label: "Hoe vaak",
                          opties: Self.intervallen.map { ($0, $0 == 0 ? "Niet herhalen" : Wanneertekst.frequentie(intervalMaanden: $0)) },
                          keuze: $interval)
                Keuzerij(label: "Wie doet het?",
                         opties: [(UitvoeringSoort.zelf, "Zelf"), (UitvoeringSoort.vakman, "Vakman"), (UitvoeringSoort.zelfOfVakman, "Beide")],
                         keuze: $uitvoering)
                OptioneleDatum(label: "Eerste keer op", datum: $eerste)

                Button("Opslaan") { bewaar() }
                    .buttonStyle(.primair)
                    .disabled(titel.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
    }

    private func bewaar() {
        let intervalMaanden: Int? = interval == 0 ? nil : interval
        if let taak {
            taak.eigenTitel = titel.trimmingCharacters(in: .whitespacesAndNewlines)
            taak.eigenUitleg = uitleg.trimmingCharacters(in: .whitespacesAndNewlines)
            taak.eigenCategorie = categorie
            taak.intervalMaanden = intervalMaanden
            taak.eigenUitvoering = uitvoering.rawValue
            taak.volgendeDatum = eerste.map { dienst.planning.kalender.startOfDay(for: $0) }
            try? context.save()
        } else {
            dienst.maakEigenTaak(woning: woning, titel: titel, uitleg: uitleg, categorie: categorie, intervalMaanden: intervalMaanden,
                                 uitvoering: uitvoering, eersteDatum: eerste ?? Date(), context: context)
        }
        let taken = woning.alleTaken
        Task { await dienst.herplanMeldingen(taken: taken) }
        dismiss()
    }
}

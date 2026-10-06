import SwiftData
import SwiftUI

/// Woningprofiel: naam, bouwjaar, type en de losse kenmerken (tags).
struct ProfielScherm: View {
    let woning: Woning

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var naam: String
    @State private var bouwjaar: String
    @State private var woningtype: String
    @State private var eigenaarSinds: Date?
    @State private var kenmerken: Set<String>

    init(woning: Woning) {
        self.woning = woning
        _naam = State(initialValue: woning.naam)
        _bouwjaar = State(initialValue: woning.bouwjaar.map(String.init) ?? "")
        _woningtype = State(initialValue: woning.woningtype)
        _eigenaarSinds = State(initialValue: woning.eigenaarSinds)
        _kenmerken = State(initialValue: Set(woning.kenmerken))
    }

    var body: some View {
        Scherm {
            Schermkop(titel: "Woning")

            VStack(alignment: .leading, spacing: Ruimte.l) {
                Invoerveld(label: "Naam", placeholder: "Bijvoorbeeld Mijn huis", tekst: $naam)
                Invoerveld(label: "Bouwjaar", placeholder: "Bijvoorbeeld 1985", tekst: $bouwjaar, toetsenbord: .numberPad)
                Invoerveld(label: "Type woning", placeholder: "Bijvoorbeeld tussenwoning", tekst: $woningtype)
                OptioneleDatum(label: "Eigenaar sinds", datum: $eigenaarSinds)
            }

            Groep(kop: "Kenmerken") {
                BladRijen(tags) { tag in
                    Toggle(Kenmerken.tagTitels[tag.id] ?? tag.id, isOn: binding(voor: tag.id))
                        .toggleStyle(.vinkje)
                }
            }
            Text("Een kenmerk aan- of uitzetten verandert je schema niet vanzelf. De app stelt het voor en jij kiest.")
                .tekststijl(.klein)
                .foregroundStyle(Color.inkMuted)

            Button("Opslaan") { bewaar() }
                .buttonStyle(.primair)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
    }

    private struct Tag: Identifiable { let id: String }

    /// Alle bekende tags, plus onbekende tags die al op de woning staan (zodat ze nooit stil verdwijnen).
    private var tags: [Tag] {
        let bekend = Kenmerken.tagTitels.keys.sorted { (Kenmerken.tagTitels[$0] ?? $0) < (Kenmerken.tagTitels[$1] ?? $1) }
        let onbekend = woning.kenmerken.filter { Kenmerken.tagTitels[$0] == nil }
        return (bekend + onbekend).map(Tag.init)
    }

    private func binding(voor tag: String) -> Binding<Bool> {
        Binding(get: { kenmerken.contains(tag) }, set: { aan in
            if aan { kenmerken.insert(tag) } else { kenmerken.remove(tag) }
        })
    }

    private func bewaar() {
        woning.naam = naam.trimmingCharacters(in: .whitespacesAndNewlines)
        woning.bouwjaar = Int(bouwjaar.trimmingCharacters(in: .whitespaces)).flatMap { (1000...3000).contains($0) ? $0 : nil }
        woning.woningtype = woningtype.trimmingCharacters(in: .whitespacesAndNewlines)
        woning.eigenaarSinds = eigenaarSinds
        // Zelfde volgorde als de rest van de app, onbekende tags blijven staan.
        woning.kenmerken = tags.map(\.id).filter { kenmerken.contains($0) }
        try? context.save()
        dismiss()
    }
}

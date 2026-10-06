import SwiftUI

/// Invoerveld: `surfaceRaised`, rand `lineStrong`, hoek 10. Het label staat erboven in `taak`.
struct Invoerveld: View {
    let label: String
    let placeholder: String
    @Binding var tekst: String
    var regels: ClosedRange<Int> = 1...1

    @FocusState private var focus: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.s) {
            Text(label)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
            TextField("", text: $tekst, prompt: Text(placeholder).foregroundStyle(Color.inkMuted), axis: .vertical)
                .lineLimit(regels)
                .tekststijl(.body)
                .foregroundStyle(Color.ink)
                .focused($focus)
                .padding(Ruimte.m)
                .frame(maxWidth: .infinity, minHeight: Ruimte.knopHoogte, alignment: .topLeading)
                .background(Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: Hoek.knop))
                .overlay(
                    RoundedRectangle(cornerRadius: Hoek.knop)
                        .strokeBorder(focus ? Color.brand : Color.lineStrong, lineWidth: focus ? 2 : 1.5)
                )
                .accessibilityLabel(label)
        }
    }
}

/// Compacte keuze tussen twee of meer opties, bijvoorbeeld "Zelf / Vakman".
/// De gekozen optie heeft een vinkje en een dikkere rand; kleur draagt het nooit alleen.
struct Keuzerij<Waarde: Hashable>: View {
    let label: String
    let opties: [(waarde: Waarde, titel: String)]
    @Binding var keuze: Waarde

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.s) {
            Text(label)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
            HStack(spacing: Ruimte.s) {
                ForEach(opties, id: \.waarde) { optie in
                    let gekozen = optie.waarde == keuze
                    Button {
                        keuze = optie.waarde
                    } label: {
                        HStack(spacing: Ruimte.xs) {
                            if gekozen { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)) }
                            Text(optie.titel)
                        }
                        .tekststijl(.taak)
                        .foregroundStyle(gekozen ? Color.brand : Color.ink)
                        .frame(maxWidth: .infinity, minHeight: Ruimte.knopHoogte)
                        .background(Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: Hoek.knop))
                        .overlay(
                            RoundedRectangle(cornerRadius: Hoek.knop)
                                .strokeBorder(gekozen ? Color.brand : Color.lineStrong, lineWidth: gekozen ? 2 : 1.5)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: Hoek.knop))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(gekozen ? .isSelected : [])
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

import SwiftUI
import UIKit

/// Invoerveld: `surfaceRaised`, rand `lineStrong`, hoek 10. Het label staat erboven in `taak`.
struct Invoerveld: View {
    let label: String
    let placeholder: String
    @Binding var tekst: String
    var regels: ClosedRange<Int> = 1...1
    var toetsenbord: UIKeyboardType = .default

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
                .keyboardType(toetsenbord)
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

/// Een datum die ook leeg mag zijn: "Datum kiezen" of de gekozen datum met "Wissen".
struct OptioneleDatum: View {
    let label: String
    @Binding var datum: Date?
    var bereik: PartialRangeThrough<Date>?

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.s) {
            Text(label)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
            HStack {
                if let waarde = datum {
                    DatePicker(label, selection: Binding(get: { waarde }, set: { datum = $0 }), displayedComponents: .date)
                        .labelsHidden()
                    Spacer(minLength: Ruimte.m)
                    Button("Wissen") { datum = nil }
                        .buttonStyle(.tekst)
                        .accessibilityLabel("\(label) wissen")
                } else {
                    Text("Niet ingevuld")
                        .tekststijl(.body)
                        .foregroundStyle(Color.inkMuted)
                    Spacer(minLength: Ruimte.m)
                    Button("Datum kiezen") { datum = Date() }
                        .buttonStyle(.tekst)
                        .accessibilityLabel("\(label) kiezen")
                }
            }
            .frame(minHeight: Ruimte.aanraakminimum)
        }
    }
}

/// Keuze uit een lijst in een menu, vormgegeven als invoerveld met het label erboven.
struct Keuzemenu<Waarde: Hashable>: View {
    let label: String
    let opties: [(waarde: Waarde, titel: String)]
    @Binding var keuze: Waarde

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.s) {
            Text(label)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
            Menu {
                ForEach(opties, id: \.waarde) { optie in
                    Button(optie.titel) { keuze = optie.waarde }
                }
            } label: {
                HStack {
                    Text(opties.first { $0.waarde == keuze }?.titel ?? "")
                        .tekststijl(.body)
                        .foregroundStyle(Color.ink)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: Ruimte.s)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.inkMuted)
                        .accessibilityHidden(true)
                }
                .padding(Ruimte.m)
                .frame(maxWidth: .infinity, minHeight: Ruimte.knopHoogte, alignment: .leading)
                .background(Color.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: Hoek.knop))
                .overlay(RoundedRectangle(cornerRadius: Hoek.knop).strokeBorder(Color.lineStrong, lineWidth: 1.5))
                .contentShape(RoundedRectangle(cornerRadius: Hoek.knop))
            }
            .accessibilityLabel(label)
            .accessibilityValue(opties.first { $0.waarde == keuze }?.titel ?? "")
        }
    }
}

/// Zoekveld bovenaan een lijst.
struct Zoekveld: View {
    @Binding var tekst: String
    @FocusState private var focus: Bool

    var body: some View {
        HStack(spacing: Ruimte.s) {
            TextField("", text: $tekst, prompt: Text("Zoeken").foregroundStyle(Color.inkMuted))
                .tekststijl(.body)
                .foregroundStyle(Color.ink)
                .focused($focus)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel("Zoeken in taken")
            if !tekst.isEmpty {
                Button {
                    tekst = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.inkMuted)
                        .frame(width: Ruimte.aanraakminimum, height: Ruimte.aanraakminimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zoekopdracht wissen")
            }
        }
        .padding(.horizontal, Ruimte.m)
        .frame(minHeight: Ruimte.knopHoogte)
        .background(Color.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: Hoek.knop))
        .overlay(
            RoundedRectangle(cornerRadius: Hoek.knop)
                .strokeBorder(focus ? Color.brand : Color.lineStrong, lineWidth: focus ? 2 : 1.5)
        )
    }
}

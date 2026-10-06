import SwiftUI

/// Eén rij op het blad. Geen chevron; de hele rij is aanraakbaar (de aanroeper
/// zet er een `Button` of `NavigationLink` omheen met `RijKnopStijl`).
struct TaakRij: View {
    let titel: String
    let status: TaakStatus
    /// Bijvoorbeeld "sinds september", "in november" of, bij gedaan, "Elk jaar".
    let wanneer: String
    var uitvoering: UitvoeringSoort?
    var duur: Int?
    var stempel: (datum: Date, door: Uitvoerder)?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Ruimte.s) {
                    tekstkolom
                    rechts
                }
            } else {
                HStack(alignment: .center, spacing: Ruimte.l) {
                    tekstkolom
                    Spacer(minLength: 0)
                    rechts
                }
            }
        }
        .padding(.vertical, Ruimte.m)
        .padding(.horizontal, Ruimte.l)
        .frame(maxWidth: .infinity, minHeight: Ruimte.rijMinHoogte, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(toegankelijkLabel)
    }

    private var tekstkolom: some View {
        VStack(alignment: .leading, spacing: Ruimte.xs) {
            Text(titel)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.leading)
            Text(statusregel)
                .tekststijl(.klein)
                .fontWeight(status == .telaat || status == .nu ? .semibold : nil)
                .foregroundStyle(statuskleur)
                .multilineTextAlignment(.leading)
        }
    }

    @ViewBuilder private var rechts: some View {
        if let stempel {
            Stempel(datum: stempel.datum, door: stempel.door)
                .padding(.trailing, Ruimte.xs)
        } else if let meta {
            Text(meta)
                .tekststijl(.klein)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 120, alignment: typeSize.isAccessibilitySize ? .leading : .trailing)
        }
    }

    /// "Zelf, 15 min"
    private var meta: String? {
        let delen = [uitvoering?.label, duur.map { "\($0) min" }].compactMap { $0 }
        return delen.isEmpty ? nil : delen.joined(separator: ", ")
    }

    private var statusregel: String {
        Wanneertekst.statusregel(status: status, wanneer: wanneer)
    }

    private var statuskleur: Color {
        switch status {
        case .telaat: .mennie
        case .nu: .oker
        case .later, .gedaan: .inkMuted
        }
    }

    private var toegankelijkLabel: String {
        var delen = [titel, statusregel]
        if let meta { delen.append(meta) }
        if let stempel {
            delen.append("Afgevinkt op \(Datumopmaak.kort(stempel.datum)), door \(stempel.door.label.lowercased())")
        }
        return delen.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// Knopstijl voor een hele rij: geen eigen kleur, alleen een rustige indruk.
struct RijKnopStijl: ButtonStyle {
    @Environment(\.isFocused) private var focus

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.line.opacity(0.5) : Color.clear)
            .overlay {
                if focus {
                    RoundedRectangle(cornerRadius: Hoek.knop).strokeBorder(Color.brand, lineWidth: 2)
                }
            }
    }
}

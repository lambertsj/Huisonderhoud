import SwiftUI

/// Een gewone rij op het blad: titel links, waarde rechts. Voor profiel, apparaten en Over.
struct Lijstrij: View {
    let titel: String
    var waarde: String?
    var uitleg: String?

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Ruimte.xs) { links; rechts }
            } else {
                HStack(alignment: .firstTextBaseline, spacing: Ruimte.l) {
                    links
                    Spacer(minLength: 0)
                    rechts
                }
            }
        }
        .padding(.horizontal, Ruimte.l)
        .padding(.vertical, Ruimte.m)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([titel, waarde, uitleg].compactMap { $0 }.joined(separator: ", "))
    }

    private var links: some View {
        VStack(alignment: .leading, spacing: Ruimte.xs) {
            Text(titel)
                .tekststijl(.taak)
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.leading)
            if let uitleg {
                Text(uitleg)
                    .tekststijl(.body)
                    .foregroundStyle(Color.inkMuted)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder private var rechts: some View {
        if let waarde {
            Text(waarde)
                .tekststijl(.klein)
                .foregroundStyle(Color.inkMuted)
                .multilineTextAlignment(.trailing)
        }
    }
}

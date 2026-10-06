import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case nu = "Nu", schema = "Schema", boekje = "Boekje", huis = "Huis"
    var id: String { rawValue }
}

/// Vier tekst-tabs, geen pictogrammen. De actieve tab is `brand` en bold.
struct Tabbalk: View {
    @Binding var gekozen: Tab

    var body: some View {
        VStack(spacing: 0) {
            Haarlijn()
            HStack(spacing: 0) {
                ForEach(Tab.allCases) { tab in
                    Button {
                        gekozen = tab
                    } label: {
                        Text(tab.rawValue)
                            .tekststijl(.taak)
                            .fontWeight(gekozen == tab ? .bold : .regular)
                            .foregroundStyle(gekozen == tab ? Color.brand : Color.inkMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(RijKnopStijl())
                    .accessibilityAddTraits(gekozen == tab ? .isSelected : [])
                }
            }
            .padding(.horizontal, Ruimte.s)
        }
        .background(Color.surfaceRaised.ignoresSafeArea(edges: .bottom))
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tabbalk")
    }
}

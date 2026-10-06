import SwiftUI

/// Haarlijn tussen rijen. Decoratief.
struct Haarlijn: View {
    @Environment(\.displayScale) private var schaal

    var body: some View {
        Rectangle()
            .fill(Color.line)
            .frame(height: 1 / schaal)
            .accessibilityHidden(true)
    }
}

/// Een scherm is één blad: `surfaceRaised`, hoek 18, rijen gescheiden door een haarlijn.
/// Zet zelf `Haarlijn()` tussen rijen, of gebruik `BladRijen` voor een lijst.
struct Blad<Inhoud: View>: View {
    private let inhoud: Inhoud

    init(@ViewBuilder inhoud: () -> Inhoud) {
        self.inhoud = inhoud()
    }

    var body: some View {
        VStack(spacing: 0) { inhoud }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Hoek.blad))
    }
}

/// Een blad met één rij per element en een haarlijn ertussen.
struct BladRijen<Element: Identifiable, Rij: View>: View {
    let elementen: [Element]
    @ViewBuilder let rij: (Element) -> Rij

    init(_ elementen: [Element], @ViewBuilder rij: @escaping (Element) -> Rij) {
        self.elementen = elementen
        self.rij = rij
    }

    var body: some View {
        Blad {
            ForEach(Array(elementen.enumerated()), id: \.element.id) { index, element in
                if index > 0 { Haarlijn() }
                rij(element)
            }
        }
    }
}

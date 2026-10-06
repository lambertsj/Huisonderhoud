import SwiftUI

enum Knopsoort { case primair, secundair, tekst }

/// 48 pt hoog, hoek 10, label 17 semibold. Labels zijn werkwoorden.
struct KnopStijl: ButtonStyle {
    let soort: Knopsoort

    @Environment(\.isEnabled) private var actief
    @Environment(\.isFocused) private var focus

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .tekststijl(.taak)
            .foregroundStyle(tekstkleur)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Ruimte.l)
            .frame(maxWidth: soort == .tekst ? nil : .infinity, minHeight: Ruimte.knopHoogte)
            .frame(minWidth: Ruimte.aanraakminimum)
            .background(achtergrond)
            .overlay {
                if soort == .secundair {
                    RoundedRectangle(cornerRadius: Hoek.knop).strokeBorder(Color.lineStrong, lineWidth: 1.5)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Hoek.knop))
            .overlay {
                if focus {
                    RoundedRectangle(cornerRadius: Hoek.knop).strokeBorder(Color.brand, lineWidth: 2).padding(-3)
                }
            }
            .opacity(actief ? (configuration.isPressed ? 0.8 : 1) : 0.45)
            .contentShape(RoundedRectangle(cornerRadius: Hoek.knop))
    }

    private var tekstkleur: Color {
        soort == .primair ? .onBrand : .brand
    }

    @ViewBuilder private var achtergrond: some View {
        if soort == .primair { Color.brand } else { Color.clear }
    }
}

extension ButtonStyle where Self == KnopStijl {
    static var primair: KnopStijl { KnopStijl(soort: .primair) }
    static var secundair: KnopStijl { KnopStijl(soort: .secundair) }
    static var tekst: KnopStijl { KnopStijl(soort: .tekst) }
}

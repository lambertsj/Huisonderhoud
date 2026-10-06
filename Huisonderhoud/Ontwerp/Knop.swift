import SwiftUI

enum Knopsoort { case primair, secundair, tekst }

/// De opmaak van een knop: 48 pt hoog, hoek 10, label 17 semibold. Los te gebruiken voor
/// bedieningselementen die zelf geen `Button` zijn, zoals een `PhotosPicker`.
struct KnopOpmaak: ViewModifier {
    let soort: Knopsoort
    var isIngedrukt = false

    @Environment(\.isEnabled) private var actief
    @Environment(\.isFocused) private var focus

    func body(content: Content) -> some View {
        content
            .tekststijl(.taak)
            .foregroundStyle(soort == .primair ? Color.onBrand : Color.brand)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Ruimte.l)
            .frame(maxWidth: soort == .tekst ? nil : .infinity, minHeight: Ruimte.knopHoogte)
            .frame(minWidth: Ruimte.aanraakminimum)
            .background(soort == .primair ? Color.brand : Color.clear)
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
            .opacity(actief ? (isIngedrukt ? 0.8 : 1) : 0.45)
            .contentShape(RoundedRectangle(cornerRadius: Hoek.knop))
    }
}

/// Knopstijl. Labels zijn werkwoorden: "Afvinken", "Notitie toevoegen", nooit "OK".
/// Maximaal één primaire knop per scherm.
struct KnopStijl: ButtonStyle {
    let soort: Knopsoort

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(KnopOpmaak(soort: soort, isIngedrukt: configuration.isPressed))
    }
}

extension ButtonStyle where Self == KnopStijl {
    static var primair: KnopStijl { KnopStijl(soort: .primair) }
    static var secundair: KnopStijl { KnopStijl(soort: .secundair) }
    static var tekst: KnopStijl { KnopStijl(soort: .tekst) }
}

extension View {
    func knopOpmaak(_ soort: Knopsoort) -> some View {
        modifier(KnopOpmaak(soort: soort))
    }
}

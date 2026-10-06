import SwiftUI

/// Checkbox-rij voor een `Toggle`: een vakje op papier, geen schakelaar.
/// Het vakje heeft de hoek van de Stempel (2 pt): het is een merkteken op het blad.
struct VinkjeStijl: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: Ruimte.l) {
                Vakje(aan: configuration.isOn)
                configuration.label
                    .tekststijl(.body)
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Ruimte.l)
            .padding(.vertical, Ruimte.m)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(RijKnopStijl())
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "aan" : "uit")
    }

    private struct Vakje: View {
        let aan: Bool

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: Hoek.stempel)
                    .fill(aan ? Color.brand : Color.clear)
                RoundedRectangle(cornerRadius: Hoek.stempel)
                    .strokeBorder(aan ? Color.brand : Color.lineStrong, lineWidth: 1.5)
                if aan {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.onBrand)
                }
            }
            .frame(width: 26, height: 26)
            .accessibilityHidden(true)
        }
    }
}

extension ToggleStyle where Self == VinkjeStijl {
    static var vinkje: VinkjeStijl { VinkjeStijl() }
}

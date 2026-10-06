import SwiftUI

/// Omlijnd blok, alleen voor veiligheid (gas, elektra, hoogte, vocht). Geen pictogram.
struct Waarschuwing: View {
    var kop: String = "Let op"
    let tekst: String

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.xs) {
            Text(kop)
                .tekststijl(.taak)
                .foregroundStyle(Color.mennie)
            Text(tekst)
                .tekststijl(.body)
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Ruimte.l)
        .overlay(
            RoundedRectangle(cornerRadius: Hoek.stempel)
                .strokeBorder(Color.mennie, lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}

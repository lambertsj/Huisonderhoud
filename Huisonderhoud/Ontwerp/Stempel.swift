import SwiftUI

/// De enige plek waar hoofdletters en `stempelblauw` bestaan. Eén per afgevinkte klus.
struct Stempel: View {
    let datum: Date
    let door: Uitvoerder
    /// Alleen true op het moment van afvinken: dan landt de stempel één keer.
    var landt: Bool = false

    @Environment(\.accessibilityReduceMotion) private var verminderBeweging
    @State private var geland = false

    var body: some View {
        VStack(spacing: 2) {
            Text("AFGEVINKT").tekststijl(.stempelTekst)
            Text(Datumopmaak.kort(datum)).tekststijl(.stempelDatum)
            Text(door.label.uppercased()).tekststijl(.stempelTekst)
        }
        .foregroundStyle(Color.stempelblauw)
        .padding(.horizontal, Ruimte.m)
        .padding(.vertical, Ruimte.s)
        .overlay(
            RoundedRectangle(cornerRadius: Hoek.stempel)
                .strokeBorder(Color.stempelblauw, lineWidth: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Hoek.stempel)
                .strokeBorder(Color.stempelblauw, lineWidth: 1)
                .padding(3 + 2)
        )
        .rotationEffect(.degrees(-2.5))
        .scaleEffect(landt && !geland && !verminderBeweging ? 1.15 : 1)
        .onAppear {
            guard landt, !geland else { return }
            Haptiek.licht()
            if verminderBeweging {
                geland = true
            } else {
                withAnimation(.easeOut(duration: 0.14)) { geland = true }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Afgevinkt op \(Datumopmaak.kort(datum)), door \(door.label.lowercased())")
    }
}

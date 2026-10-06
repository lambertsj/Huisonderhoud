import SwiftUI

/// De vier tabs. Alle schermen blijven bestaan, zodat de navigatie per tab bewaard blijft.
struct HoofdView: View {
    @State private var tab: Tab = Self.starttab

    var body: some View {
        ZStack {
            inhoud(.nu) { NuScherm() }
            inhoud(.schema) { SchemaScherm() }
            inhoud(.boekje) { BoekjeScherm() }
            inhoud(.huis) { HuisScherm() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Tabbalk(gekozen: $tab)
        }
        .background(Color.surface.ignoresSafeArea())
    }

    private static var starttab: Tab {
        #if DEBUG
        // Voor screenshots: `-tab boekje` start op die tab.
        if let i = CommandLine.arguments.firstIndex(of: "-tab"), i + 1 < CommandLine.arguments.count,
           let tab = Tab(rawValue: CommandLine.arguments[i + 1].capitalized) { return tab }
        #endif
        return .nu
    }

    private func inhoud<V: View>(_ doel: Tab, @ViewBuilder _ inhoud: () -> V) -> some View {
        inhoud()
            .opacity(tab == doel ? 1 : 0)
            .allowsHitTesting(tab == doel)
            .accessibilityHidden(tab != doel)
    }
}

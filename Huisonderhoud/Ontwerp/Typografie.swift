import SwiftUI
import UIKit

/// Tekststijlen uit docs/ONTWERP.md. Alle stijlen schalen mee met Dynamic Type.
enum Tekststijl {
    case titelGroot, kop, taak, body, uitleg, klein, stempelTekst, stempelDatum

    private enum Familie { case schibsted, barlow }

    private struct Spec {
        let familie: Familie
        let gewicht: Font.Weight
        let grootte: CGFloat
        let regelhoogte: CGFloat
        /// Spatiëring in em.
        let spatieEm: CGFloat
        let relatief: Font.TextStyle
    }

    private var spec: Spec {
        switch self {
        case .titelGroot: Spec(familie: .schibsted, gewicht: .bold, grootte: 34, regelhoogte: 38, spatieEm: -0.01, relatief: .largeTitle)
        case .kop: Spec(familie: .schibsted, gewicht: .bold, grootte: 22, regelhoogte: 28, spatieEm: 0, relatief: .title2)
        case .taak: Spec(familie: .schibsted, gewicht: .semibold, grootte: 17, regelhoogte: 22, spatieEm: 0, relatief: .body)
        case .body: Spec(familie: .schibsted, gewicht: .regular, grootte: 17, regelhoogte: 24, spatieEm: 0, relatief: .body)
        case .uitleg: Spec(familie: .schibsted, gewicht: .regular, grootte: 17, regelhoogte: 26, spatieEm: 0, relatief: .body)
        case .klein: Spec(familie: .schibsted, gewicht: .medium, grootte: 13, regelhoogte: 18, spatieEm: 0, relatief: .footnote)
        case .stempelTekst: Spec(familie: .barlow, gewicht: .semibold, grootte: 13, regelhoogte: 14, spatieEm: 0.08, relatief: .footnote)
        case .stempelDatum: Spec(familie: .barlow, gewicht: .bold, grootte: 24, regelhoogte: 24, spatieEm: 0.02, relatief: .title2)
        }
    }

    /// PostScript-namen, gecontroleerd aan de lettertypebestanden zelf.
    static func postScriptNaam(familie: String, gewicht: Font.Weight) -> String {
        switch (familie, gewicht) {
        case ("schibsted", .bold): "SchibstedGrotesk-Bold"
        case ("schibsted", .semibold): "SchibstedGrotesk-SemiBold"
        case ("schibsted", .medium): "SchibstedGrotesk-Medium"
        case ("schibsted", _): "SchibstedGrotesk-Regular"
        case (_, .bold): "BarlowCondensed-Bold"
        default: "BarlowCondensed-SemiBold"
        }
    }

    fileprivate var fontNaam: String {
        Self.postScriptNaam(familie: spec.familie == .schibsted ? "schibsted" : "barlow", gewicht: spec.gewicht)
    }

    /// De regelhoogte die het lettertype zelf al meebrengt. `lineSpacing` komt daar bovenop,
    /// dus alleen het verschil met de gewenste regelhoogte telt.
    var natuurlijkeRegelhoogte: CGFloat {
        UIFont(name: fontNaam, size: spec.grootte)?.lineHeight ?? spec.grootte * 1.2
    }

    /// De grote titel schaalt tot en met accessibility2 mee. Daarboven passen lange woorden
    /// ("Rookmelders") niet meer op één regel en breekt de tekst midden in een woord.
    var grootsteMaat: DynamicTypeSize {
        switch self {
        case .titelGroot: .accessibility2
        case .kop: .accessibility3
        default: .accessibility5
        }
    }

    var grootte: CGFloat { spec.grootte }
    var regelhoogte: CGFloat { spec.regelhoogte }
    var relatiefAan: Font.TextStyle { spec.relatief }
    var spatieEm: CGFloat { spec.spatieEm }
    var isStempel: Bool { spec.familie == .barlow }

    /// Het lettertype; valt terug op het systeemlettertype als het bestand ontbreekt.
    var font: Font {
        if UIFont(name: fontNaam, size: spec.grootte) != nil {
            return .custom(fontNaam, size: spec.grootte, relativeTo: spec.relatief)
        }
        return .system(size: spec.grootte, weight: spec.gewicht)
    }
}

private struct TekststijlModifier: ViewModifier {
    let stijl: Tekststijl
    @ScaledMetric private var extraRegelruimte: CGFloat
    @ScaledMetric private var spatie: CGFloat

    init(_ stijl: Tekststijl) {
        self.stijl = stijl
        _extraRegelruimte = ScaledMetric(wrappedValue: max(stijl.regelhoogte - stijl.natuurlijkeRegelhoogte, 0), relativeTo: stijl.relatiefAan)
        _spatie = ScaledMetric(wrappedValue: stijl.grootte * stijl.spatieEm, relativeTo: stijl.relatiefAan)
    }

    func body(content: Content) -> some View {
        content
            .font(stijl.font)
            .tracking(spatie)
            .lineSpacing(extraRegelruimte)
            .dynamicTypeSize(...stijl.grootsteMaat)
    }
}

extension View {
    func tekststijl(_ stijl: Tekststijl) -> some View {
        modifier(TekststijlModifier(stijl))
    }
}

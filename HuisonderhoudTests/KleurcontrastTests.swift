import Testing
import UIKit
@testable import Huisonderhoud

struct KleurcontrastTests {
    enum Thema: String, CaseIterable { case licht, donker }

    private func kleur(_ token: Kleurtoken, _ thema: Thema) -> UIColor {
        let trait = UITraitCollection(userInterfaceStyle: thema == .licht ? .light : .dark)
        guard let kleur = UIColor(named: token.rawValue, in: Bundle(for: Hulp.self).appBundle, compatibleWith: trait) else {
            Issue.record("Kleur \(token.rawValue) ontbreekt in de asset catalog")
            return .magenta
        }
        // Resolve naar sRGB zodat de componenten kloppen.
        return kleur.resolvedColor(with: trait)
    }

    private func luminantie(_ kleur: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        kleur.getRed(&r, green: &g, blue: &b, alpha: &a)
        func lineair(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * lineair(r) + 0.7152 * lineair(g) + 0.0722 * lineair(b)
    }

    func contrast(_ a: Kleurtoken, _ b: Kleurtoken, _ thema: Thema) -> Double {
        let la = luminantie(kleur(a, thema)), lb = luminantie(kleur(b, thema))
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    @Test("Tekstkleuren halen 4,5:1 op surface en surfaceRaised", arguments: Thema.allCases)
    func tekstContrast(thema: Thema) {
        let tekst: [Kleurtoken] = [.ink, .inkMuted, .brand, .mennie, .oker, .stempelblauw]
        for t in tekst {
            for ondergrond in [Kleurtoken.surface, .surfaceRaised] {
                let c = contrast(t, ondergrond, thema)
                #expect(c >= 4.5, "\(t.rawValue) op \(ondergrond.rawValue) (\(thema.rawValue)): \(String(format: "%.2f", c))")
            }
        }
    }

    @Test("onBrand op brand haalt 4,5:1", arguments: Thema.allCases)
    func onBrand(thema: Thema) {
        let c = contrast(.onBrand, .brand, thema)
        #expect(c >= 4.5, "onBrand op brand (\(thema.rawValue)): \(String(format: "%.2f", c))")
    }

    @Test("Randen van velden en knoppen halen 3:1", arguments: Thema.allCases)
    func randen(thema: Thema) {
        for rand in [Kleurtoken.lineStrong, .brand] {
            for ondergrond in [Kleurtoken.surface, .surfaceRaised] {
                let c = contrast(rand, ondergrond, thema)
                #expect(c >= 3.0, "\(rand.rawValue) op \(ondergrond.rawValue) (\(thema.rawValue)): \(String(format: "%.2f", c))")
            }
        }
    }
}

private final class Hulp {}
private extension Bundle {
    /// De bundle van de app (waar de asset catalog in zit), ook als de tests gehost draaien.
    var appBundle: Bundle { Bundle(for: HuisonderhoudBundleAnker.self) }
}

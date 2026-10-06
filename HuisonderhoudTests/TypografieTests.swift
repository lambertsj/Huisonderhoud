import Testing
import UIKit
@testable import Huisonderhoud

struct TypografieTests {
    @Test("De gebundelde lettertypen zijn registreerbaar onder hun PostScript-naam")
    func lettertypenAanwezig() {
        let namen = [
            "SchibstedGrotesk-Regular", "SchibstedGrotesk-Medium", "SchibstedGrotesk-SemiBold",
            "SchibstedGrotesk-Bold", "BarlowCondensed-SemiBold", "BarlowCondensed-Bold",
        ]
        for naam in namen {
            #expect(UIFont(name: naam, size: 17) != nil, "Lettertype \(naam) niet gevonden")
        }
    }

    @Test("Stempel is de enige stijl in Barlow Condensed")
    func barlowAlleenInStempel() {
        let alle: [Tekststijl] = [.titelGroot, .kop, .taak, .body, .uitleg, .klein, .stempelTekst, .stempelDatum]
        for stijl in alle {
            #expect(stijl.isStempel == (stijl == .stempelTekst || stijl == .stempelDatum))
        }
    }
}

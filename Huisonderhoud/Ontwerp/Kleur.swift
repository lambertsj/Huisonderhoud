import SwiftUI

/// Kleurtokens uit docs/ONTWERP.md. De waarden (licht en donker) staan in
/// Resources/Assets.xcassets; hier staan alleen de namen.
extension Color {
    static let surface = Color("surface")
    static let surfaceRaised = Color("surfaceRaised")
    static let ink = Color("ink")
    static let inkMuted = Color("inkMuted")
    static let line = Color("line")
    static let lineStrong = Color("lineStrong")
    static let brand = Color("brand")
    static let onBrand = Color("onBrand")
    static let mennie = Color("mennie")
    static let oker = Color("oker")
    static let stempelblauw = Color("stempelblauw")
}

/// Namen van alle tokens, voor de contrasttest.
enum Kleurtoken: String, CaseIterable {
    case surface, surfaceRaised, ink, inkMuted, line, lineStrong
    case brand, onBrand, mennie, oker, stempelblauw
}

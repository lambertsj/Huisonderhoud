import CoreGraphics

/// Ruimte en hoeken. Drie hoeken, elk met een eigen rol.
enum Ruimte {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 40

    static let schermrand: CGFloat = 16
    static let rijMinHoogte: CGFloat = 64
    static let knopHoogte: CGFloat = 48
    static let aanraakminimum: CGFloat = 44
}

enum Hoek {
    /// De Stempel en de Waarschuwing.
    static let stempel: CGFloat = 2
    /// Knoppen en invoervelden.
    static let knop: CGFloat = 10
    /// Het blad.
    static let blad: CGFloat = 18
}

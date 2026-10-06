import SwiftUI

/// Gedeelde, onveranderlijke hulpmiddelen via de omgeving.
private struct NuKey: EnvironmentKey {
    static let defaultValue: @Sendable () -> Date = { Date() }
}

extension EnvironmentValues {
    /// De huidige tijd. Overschrijfbaar in previews en tests.
    var nu: @Sendable () -> Date {
        get { self[NuKey.self] }
        set { self[NuKey.self] = newValue }
    }
}

import SwiftUI

@main
struct HuisonderhoudApp: App {
    var body: some Scene {
        WindowGroup {
            Ontwerpgalerij()
        }
    }
}

/// Anker om de app-bundle te vinden vanuit tests.
final class HuisonderhoudBundleAnker {}

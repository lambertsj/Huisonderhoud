import SwiftData
import SwiftUI

@main
struct HuisonderhoudApp: App {
    private let container: ModelContainer
    private let dienst: Result<Huisdienst, Error>

    init() {
        // Bij de allereerste start bestaat de map nog niet; SwiftData meldt dat anders als fout in de log.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        do {
            #if DEBUG
            // Voor screenshots en handmatig testen: `-voorbeelddata` start met een gevuld, in-memory schema.
            if CommandLine.arguments.contains("-voorbeelddata") {
                container = MainActor.assumeIsolated { Voorbeeld.container(nu: Date()) }
            } else {
                container = try ModelContainer(for: Schema(Bijlage.schema))
            }
            #else
            container = try ModelContainer(for: Schema(Bijlage.schema))
            #endif
        } catch {
            fatalError("Kon de opslag niet openen: \(error)")
        }
        dienst = Result { Huisdienst(catalogus: try Catalogus.gebundeld()) }
    }

    var body: some Scene {
        WindowGroup {
            switch dienst {
            case .success(let dienst):
                WortelView()
                    .environment(dienst)
                    .modelContainer(container)
                    .environment(\.locale, Locale(identifier: "nl_NL"))
            case .failure(let fout):
                CatalogusFoutView(fout: fout)
            }
        }
    }
}

/// Anker om de app-bundle te vinden vanuit tests.
final class HuisonderhoudBundleAnker {}

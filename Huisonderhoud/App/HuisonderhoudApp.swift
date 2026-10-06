import SwiftData
import SwiftUI

@main
struct HuisonderhoudApp: App {
    private enum Opstart {
        case klaar(ModelContainer, Huisdienst)
        case fout(String)
    }

    private let opstart: Opstart

    init() {
        // Bij de allereerste start bestaat de map nog niet; SwiftData meldt dat anders als fout in de log.
        try? FileManager.default.createDirectory(at: .applicationSupportDirectory, withIntermediateDirectories: true)
        do {
            let catalogus = try Catalogus.gebundeld()
            let container = try Self.maakContainer()
            opstart = .klaar(container, MainActor.assumeIsolated { Huisdienst(catalogus: catalogus) })
        } catch Catalogus.Fout.bestandOntbreekt {
            opstart = .fout("Het bestand met onderhoudstaken ontbreekt in de app.")
        } catch let fout as Catalogus.Fout {
            opstart = .fout("Het bestand met onderhoudstaken is onleesbaar. \(fout)")
        } catch {
            opstart = .fout("De opslag op je telefoon kon niet worden geopend. \(error.localizedDescription)")
        }
    }

    private static func maakContainer() throws -> ModelContainer {
        #if DEBUG
        // Voor screenshots en UI-tests: `-voorbeelddata` start met een gevuld schema, `-leeg` met een lege opslag.
        // Beide leven alleen in het geheugen.
        if CommandLine.arguments.contains("-voorbeelddata") {
            return MainActor.assumeIsolated { Voorbeeld.container(nu: Date()) }
        }
        if CommandLine.arguments.contains("-leeg") {
            return MainActor.assumeIsolated { Voorbeeld.container(metSchema: false) }
        }
        #endif
        return try ModelContainer(for: Schema(Bijlage.schema))
    }

    var body: some Scene {
        WindowGroup {
            switch opstart {
            case .klaar(let container, let dienst):
                WortelView()
                    .environment(dienst)
                    .modelContainer(container)
                    .environment(\.locale, Locale(identifier: "nl_NL"))
            case .fout(let tekst):
                StartfoutView(tekst: tekst)
            }
        }
    }
}

/// Anker om de app-bundle te vinden vanuit tests.
final class HuisonderhoudBundleAnker {}

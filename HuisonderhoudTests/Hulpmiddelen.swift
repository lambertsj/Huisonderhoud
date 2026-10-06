import Foundation
@testable import Huisonderhoud

/// Vaste kalender en datums, zodat tests niet van de klok of tijdzone afhangen.
enum Testtijd {
    static let kalender: Calendar = {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
        k.locale = Locale(identifier: "nl_NL")
        return k
    }()

    static func datum(_ jaar: Int, _ maand: Int, _ dag: Int, uur: Int = 12) -> Date {
        kalender.date(from: DateComponents(year: jaar, month: maand, day: dag, hour: uur))!
    }

    static func onderdelen(_ datum: Date) -> (jaar: Int, maand: Int, dag: Int) {
        let c = kalender.dateComponents([.year, .month, .day], from: datum)
        return (c.year!, c.month!, c.day!)
    }

    static let planning = Planning(kalender: kalender)
}

func gebundeldeCatalogus() throws -> Catalogus {
    try Catalogus.gebundeld()
}

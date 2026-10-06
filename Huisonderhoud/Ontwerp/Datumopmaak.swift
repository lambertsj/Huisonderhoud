import Foundation

/// Nederlandse datumnotatie zoals in het ontwerp: "3 okt 2026".
enum Datumopmaak {
    private static let locale = Locale(identifier: "nl_NL")

    static func kort(_ datum: Date, kalender: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = kalender
        f.timeZone = kalender.timeZone
        f.dateFormat = "d MMM yyyy"
        return f.string(from: datum).replacingOccurrences(of: ".", with: "")
    }

    /// "Dinsdag 6 oktober", met hoofdletter vooraan.
    static func dagMaand(_ datum: Date, kalender: Calendar = .current) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.calendar = kalender
        f.timeZone = kalender.timeZone
        f.dateFormat = "EEEE d MMMM"
        let tekst = f.string(from: datum)
        return tekst.prefix(1).uppercased() + tekst.dropFirst()
    }

    /// "oktober"
    static func maandnaam(_ maand: Int) -> String {
        let namen = ["januari", "februari", "maart", "april", "mei", "juni", "juli",
                     "augustus", "september", "oktober", "november", "december"]
        return namen[(maand - 1 + 12) % 12]
    }
}

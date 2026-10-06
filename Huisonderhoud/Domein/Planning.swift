import Foundation

/// Pure planningslogica: volgende datum en status. Geen UI, geen SwiftData.
struct Planning {
    var kalender: Calendar

    init(kalender: Calendar = .current) {
        self.kalender = kalender
    }

    /// Voorkeursmaanden zonder ongeldige waarden, gesorteerd.
    static func geldigeMaanden(_ maanden: [Int]) -> [Int] {
        Array(Set(maanden.filter { (1...12).contains($0) })).sorted()
    }

    /// Stabiele dag in de maand (1 tot en met 20) per taak. Voorkomt dat alle taken van
    /// één voorkeursmaand op de eerste dag van die maand tegelijk een melding geven.
    static func spreidingsdag(voor id: String) -> Int {
        var hash: UInt64 = 0xcbf29ce484222325 // FNV-1a
        for byte in id.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return 1 + Int(hash % 20)
    }

    /// Volgende datum na het afvinken: `datum + intervalMaanden`, daarna gesnapt naar de
    /// eerstvolgende voorkeursmaand. nil als de taak niet vanzelf terugkomt.
    func volgendeDatum(na datum: Date, intervalMaanden: Int?, voorkeursMaanden: [Int], dagInMaand: Int = 1) -> Date? {
        guard let interval = intervalMaanden, interval > 0,
              let basis = kalender.date(byAdding: .month, value: interval, to: kalender.startOfDay(for: datum))
        else { return nil }
        return snap(basis, naarMaanden: voorkeursMaanden, dagInMaand: dagInMaand)
    }

    /// Valt de datum in een voorkeursmaand, dan blijft hij staan. Anders wordt het de
    /// `dagInMaand` van de eerstvolgende voorkeursmaand. Zo schuift een jaarlijkse
    /// taak niet langzaam van november naar januari.
    func snap(_ datum: Date, naarMaanden maanden: [Int], dagInMaand: Int = 1) -> Date {
        let voorkeur = Self.geldigeMaanden(maanden)
        let dag = kalender.startOfDay(for: datum)
        guard !voorkeur.isEmpty else { return dag }
        let maand = kalender.component(.month, from: dag)
        if voorkeur.contains(maand) { return dag }
        for afstand in 1...12 {
            let kandidaat = (maand - 1 + afstand) % 12 + 1
            if voorkeur.contains(kandidaat) {
                return datumInMaand(maandenVooruit: afstand, vanaf: dag, dag: dagInMaand)
            }
        }
        return dag
    }

    /// De eerstvolgende voorkeursmaand strikt na de maand van `datum`.
    func eersteDatumInVolgendeVoorkeursmaand(na datum: Date, maanden: [Int], dagInMaand: Int = 1) -> Date? {
        let voorkeur = Self.geldigeMaanden(maanden)
        guard !voorkeur.isEmpty else { return nil }
        let maand = kalender.component(.month, from: datum)
        for afstand in 1...12 {
            let kandidaat = (maand - 1 + afstand) % 12 + 1
            if voorkeur.contains(kandidaat) {
                return datumInMaand(maandenVooruit: afstand, vanaf: datum, dag: dagInMaand)
            }
        }
        return nil
    }

    private func datumInMaand(maandenVooruit n: Int, vanaf datum: Date, dag: Int) -> Date {
        let start = kalender.date(from: kalender.dateComponents([.year, .month], from: datum)) ?? datum
        let doel = kalender.date(byAdding: .month, value: n, to: start) ?? start
        let dagenInMaand = kalender.range(of: .day, in: .month, for: doel)?.count ?? 28
        var delen = kalender.dateComponents([.year, .month], from: doel)
        delen.day = min(max(dag, 1), dagenInMaand)
        return kalender.date(from: delen).map { kalender.startOfDay(for: $0) } ?? doel
    }

    /// Status van een taak op `nu`.
    /// - telaat: de datum ligt in het verleden (met voorkeursmaanden: de maand is voorbij).
    /// - nu: de datum valt in de huidige kalendermaand.
    /// - later: alles daarna, en taken zonder datum.
    func status(volgendeDatum: Date?, voorkeursMaanden: [Int], nu: Date) -> TaakStatus {
        guard let datum = volgendeDatum else { return .later }
        let metVoorkeur = !Self.geldigeMaanden(voorkeursMaanden).isEmpty
        let maandDatum = maandIndex(datum)
        let maandNu = maandIndex(nu)
        if maandDatum > maandNu { return .later }
        if maandDatum == maandNu {
            if !metVoorkeur, kalender.startOfDay(for: datum) < kalender.startOfDay(for: nu) { return .telaat }
            return .nu
        }
        return .telaat
    }

    private func maandIndex(_ datum: Date) -> Int {
        let c = kalender.dateComponents([.year, .month], from: datum)
        return (c.year ?? 0) * 12 + (c.month ?? 1)
    }
}

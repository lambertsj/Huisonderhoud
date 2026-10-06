import Foundation
import Testing
@testable import Huisonderhoud

struct MeldingplannerTests {
    private func kandidaat(_ n: Int, dagen: Int, actief: Bool = true, aan: Bool = true, nu: Date) -> MeldingKandidaat {
        let datum = Testtijd.kalender.date(byAdding: .day, value: dagen, to: Testtijd.kalender.startOfDay(for: nu))
        return MeldingKandidaat(id: UUID(), titel: "Taak \(n)", volgendeDatum: datum, isActief: actief, herinneringAan: aan)
    }

    @Test("Nooit meer dan 50 meldingen, in volgorde van datum")
    func maximum() {
        let nu = Testtijd.datum(2026, 10, 6, uur: 8)
        // 120 kandidaten in omgekeerde volgorde aangeleverd.
        let kandidaten = (1...120).reversed().map { kandidaat($0, dagen: $0, nu: nu) }
        let plan = Meldingplanner.plan(kandidaten, nu: nu, kalender: Testtijd.kalender)
        #expect(plan.count == 50)
        #expect(plan.map(\.moment) == plan.map(\.moment).sorted())
        #expect(plan.first?.titel == "Taak 1")
        #expect(plan.last?.titel == "Taak 50")
    }

    @Test("Melding om 09:00 lokale tijd")
    func negenUur() {
        let nu = Testtijd.datum(2026, 10, 6, uur: 8)
        let plan = Meldingplanner.plan([kandidaat(1, dagen: 3, nu: nu)], nu: nu, kalender: Testtijd.kalender)
        let c = Testtijd.kalender.dateComponents([.hour, .minute, .day], from: plan[0].moment)
        #expect(c.hour == 9 && c.minute == 0 && c.day == 9)
    }

    @Test("Uitgezette taken, uitgezette herinneringen, taken zonder datum en verleden worden overgeslagen")
    func filters() {
        let nu = Testtijd.datum(2026, 10, 6, uur: 8)
        let zonderDatum = MeldingKandidaat(id: UUID(), titel: "x", volgendeDatum: nil, isActief: true, herinneringAan: true)
        let lijst = [
            kandidaat(1, dagen: 2, actief: false, nu: nu),
            kandidaat(2, dagen: 2, aan: false, nu: nu),
            kandidaat(3, dagen: -2, nu: nu),
            zonderDatum,
            kandidaat(4, dagen: 2, nu: nu),
        ]
        let plan = Meldingplanner.plan(lijst, nu: nu, kalender: Testtijd.kalender)
        #expect(plan.map(\.titel) == ["Taak 4"])
    }

    @Test("Vandaag om 09:00 telt alleen als dat moment nog niet voorbij is")
    func vandaag() {
        let vroeg = Testtijd.datum(2026, 10, 6, uur: 8)
        let laat = Testtijd.datum(2026, 10, 6, uur: 10)
        let k = kandidaat(1, dagen: 0, nu: vroeg)
        #expect(Meldingplanner.plan([k], nu: vroeg, kalender: Testtijd.kalender).count == 1)
        #expect(Meldingplanner.plan([k], nu: laat, kalender: Testtijd.kalender).isEmpty)
    }

    @Test("Identifiers zijn uniek en herkenbaar")
    func identifiers() {
        let nu = Testtijd.datum(2026, 10, 6, uur: 8)
        let plan = Meldingplanner.plan((1...10).map { kandidaat($0, dagen: $0, nu: nu) }, nu: nu, kalender: Testtijd.kalender)
        #expect(Set(plan.map(\.identifier)).count == 10)
        #expect(plan.allSatisfy { $0.identifier.hasPrefix("taak-") })
    }
}

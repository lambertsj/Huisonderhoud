import Foundation
import Testing
@testable import Huisonderhoud

struct PlanningTests {
    let planning = Testtijd.planning

    // MARK: Volgende datum

    @Test("Zonder voorkeursmaanden: afvinkdatum plus interval")
    func zonderVoorkeur() {
        let d = planning.volgendeDatum(na: Testtijd.datum(2026, 10, 3), intervalMaanden: 6, voorkeursMaanden: [])
        #expect(d == Testtijd.datum(2027, 4, 3, uur: 0))
    }

    @Test("Interval null komt niet vanzelf terug")
    func geenInterval() {
        #expect(planning.volgendeDatum(na: Testtijd.datum(2026, 10, 3), intervalMaanden: nil, voorkeursMaanden: [4]) == nil)
        #expect(planning.volgendeDatum(na: Testtijd.datum(2026, 10, 3), intervalMaanden: 0, voorkeursMaanden: []) == nil)
    }

    @Test("Met voorkeursmaanden: snap naar de eerstvolgende voorkeursmaand")
    func snapVooruit() {
        // 5 okt 2026 + 12 mnd = 5 okt 2027, valt niet in [4]: dus 1 apr 2028.
        let d = planning.volgendeDatum(na: Testtijd.datum(2026, 10, 5), intervalMaanden: 12, voorkeursMaanden: [4])
        #expect(Testtijd.onderdelen(d!) == (2028, 4, 1))
    }

    @Test("Valt de datum al in een voorkeursmaand, dan blijft hij staan")
    func blijftInVoorkeursmaand() {
        let d = planning.volgendeDatum(na: Testtijd.datum(2026, 11, 20), intervalMaanden: 12, voorkeursMaanden: [10, 11])
        #expect(Testtijd.onderdelen(d!) == (2027, 11, 20))
    }

    @Test("Jaarwisseling: snap van november naar januari")
    func jaarwisseling() {
        let d = planning.snap(Testtijd.datum(2026, 11, 15), naarMaanden: [1, 2])
        #expect(Testtijd.onderdelen(d) == (2027, 1, 1))
    }

    @Test("Snap kiest de dichtstbijzijnde voorkeursmaand vooruit")
    func meerdereVoorkeuren() {
        // Van april: voorkeur [2, 9] -> september, niet februari.
        let d = planning.snap(Testtijd.datum(2026, 4, 10), naarMaanden: [2, 9])
        #expect(Testtijd.onderdelen(d) == (2026, 9, 1))
    }

    @Test("Spreidingsdag valt in een korte maand binnen de maand")
    func korteMaand() {
        let d = planning.snap(Testtijd.datum(2026, 1, 10), naarMaanden: [2], dagInMaand: 20)
        #expect(Testtijd.onderdelen(d) == (2026, 2, 20))
        let schrikkel = planning.snap(Testtijd.datum(2027, 12, 10), naarMaanden: [2], dagInMaand: 31)
        #expect(Testtijd.onderdelen(schrikkel) == (2028, 2, 29))
    }

    @Test("Ongeldige voorkeursmaanden worden genegeerd")
    func ongeldigeMaanden() {
        let d = planning.snap(Testtijd.datum(2026, 3, 3), naarMaanden: [0, 13, -1])
        #expect(Testtijd.onderdelen(d) == (2026, 3, 3))
    }

    @Test("Spreidingsdag is stabiel en tussen 1 en 20")
    func spreidingsdag() {
        let a = Planning.spreidingsdag(voor: "dak-goten-najaar")
        #expect(a == Planning.spreidingsdag(voor: "dak-goten-najaar"))
        #expect((1...20).contains(a))
    }

    // MARK: Status

    @Test("Status: te laat, nu en later zonder voorkeursmaanden")
    func statusZonderVoorkeur() {
        let nu = Testtijd.datum(2026, 10, 15)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 10, 14), voorkeursMaanden: [], nu: nu) == .telaat)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 9, 30), voorkeursMaanden: [], nu: nu) == .telaat)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 10, 15, uur: 0), voorkeursMaanden: [], nu: nu) == .nu)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 10, 31), voorkeursMaanden: [], nu: nu) == .nu)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 11, 1), voorkeursMaanden: [], nu: nu) == .later)
    }

    @Test("Status met voorkeursmaanden: te laat pas als de voorkeursmaand voorbij is")
    func statusMetVoorkeur() {
        let nu = Testtijd.datum(2026, 10, 15)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 10, 1), voorkeursMaanden: [10], nu: nu) == .nu)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 9, 1), voorkeursMaanden: [9], nu: nu) == .telaat)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2027, 4, 1), voorkeursMaanden: [4], nu: nu) == .later)
    }

    @Test("Status over de jaarwisseling")
    func statusJaarwisseling() {
        let nu = Testtijd.datum(2027, 1, 5)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2026, 12, 20), voorkeursMaanden: [], nu: nu) == .telaat)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2027, 2, 1), voorkeursMaanden: [], nu: nu) == .later)
        let december = Testtijd.datum(2026, 12, 31)
        #expect(planning.status(volgendeDatum: Testtijd.datum(2027, 1, 2), voorkeursMaanden: [], nu: december) == .later)
    }

    @Test("Zonder datum is een taak later")
    func zonderDatum() {
        #expect(planning.status(volgendeDatum: nil, voorkeursMaanden: [], nu: Testtijd.datum(2026, 10, 1)) == .later)
    }
}

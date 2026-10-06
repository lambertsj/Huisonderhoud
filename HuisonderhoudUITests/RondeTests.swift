import XCTest

/// Rooktest door de hele app: onboarding, Nu, taakdetail, afvinken, Boekje.
/// Draait met `-leeg`: een lege opslag in het geheugen, dus elke run begint bij de onboarding.
final class RondeTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func start(extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-leeg", "-AppleLanguages", "(nl)", "-AppleLocale", "nl_NL"] + extra
        app.launch()
        return app
    }

    /// Scrolt tot het element zichtbaar en aanraakbaar is.
    private func tikOp(_ element: XCUIElement, in app: XCUIApplication, bestandNaam: StaticString = #file, regel: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(element) bestaat niet", file: bestandNaam, line: regel)
        var pogingen = 0
        while !element.isHittable && pogingen < 8 {
            app.swipeUp()
            pogingen += 1
        }
        element.tap()
    }

    private func element(_ app: XCUIApplication, beginMet tekst: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", tekst)).firstMatch
    }

    private func exact(_ app: XCUIApplication, _ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    func testVolledigeRonde() {
        let app = start()

        // Onboarding: kies een cv-ketel en maak het schema.
        XCTAssertTrue(app.staticTexts["Jouw huis"].waitForExistence(timeout: 10))
        tikOp(exact(app, "Cv-ketel"), in: app)
        tikOp(exact(app, "Tuin"), in: app)
        tikOp(app.buttons["Schema maken"], in: app)

        // Zware taken: overslaan ("Weet ik niet").
        XCTAssertTrue(app.staticTexts["Wanneer deed je dit voor het laatst?"].waitForExistence(timeout: 5))
        tikOp(app.buttons["Overslaan"], in: app)

        // Meldingen: nu niet (geen systeemvraag in de test).
        XCTAssertTrue(app.staticTexts["Herinneringen"].waitForExistence(timeout: 5))
        tikOp(app.buttons["Nu niet"], in: app)

        // Nu.
        XCTAssertTrue(app.staticTexts["Nu aan de beurt"].waitForExistence(timeout: 5))
        let rij = element(app, beginMet: "Rookmelders testen")
        tikOp(rij, in: app)

        // Taakdetail.
        XCTAssertTrue(app.staticTexts["Rookmelders testen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Let op"].exists, "de waarschuwing hoort bij deze taak")
        let notitie = app.textFields["Notitie"]
        tikOp(notitie, in: app)
        notitie.typeText("Batterij van de gang vervangen")
        tikOp(app.buttons["Afvinken"], in: app)

        // De stempel landt, daarna sluit het scherm.
        XCTAssertTrue(element(app, beginMet: "Afgevinkt op").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Nu aan de beurt"].waitForExistence(timeout: 5))

        // Boekje: de stempel staat erin.
        app.buttons["Boekje"].tap()
        XCTAssertTrue(app.staticTexts["Boekje"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Afgevinkt op'")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Dossier als pdf bewaren"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Nog niets afgevinkt. Vink een klus af en hier verschijnt je eerste stempel."].exists)
    }

    func testTabsEnLegeStaten() {
        let app = start()
        tikOp(app.buttons["Schema maken"], in: app)
        // Zonder kenmerken zijn er geen zware taken: het scherm "laatste keer" wordt overgeslagen.
        XCTAssertFalse(app.buttons["Overslaan"].waitForExistence(timeout: 1))
        tikOp(app.buttons["Nu niet"], in: app)
        XCTAssertTrue(app.staticTexts["Nu aan de beurt"].waitForExistence(timeout: 5))

        app.buttons["Boekje"].tap()
        XCTAssertTrue(app.staticTexts["Nog niets afgevinkt. Vink een klus af en hier verschijnt je eerste stempel."].waitForExistence(timeout: 5))

        app.buttons["Schema"].tap()
        XCTAssertTrue(app.buttons["Taak toevoegen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Zoeken in taken"].exists)

        app.buttons["Huis"].tap()
        XCTAssertTrue(app.staticTexts["Herinneringen"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Gegevens importeren"].exists || app.buttons["Gegevens exporteren"].exists)
    }

    func testEigenTaakToevoegen() {
        let app = start()
        tikOp(app.buttons["Schema maken"], in: app)
        // Zonder kenmerken zijn er geen zware taken: het scherm "laatste keer" wordt overgeslagen.
        XCTAssertFalse(app.buttons["Overslaan"].waitForExistence(timeout: 1))
        tikOp(app.buttons["Nu niet"], in: app)
        app.buttons["Schema"].tap()
        tikOp(app.buttons["Taak toevoegen"], in: app)

        let titel = app.textFields["Titel"]
        tikOp(titel, in: app)
        titel.typeText("Dakkapel schoonmaken")
        tikOp(app.buttons["Opslaan"], in: app)

        // Terug in het schema: zoeken vindt de taak.
        let zoek = app.textFields["Zoeken in taken"]
        tikOp(zoek, in: app)
        zoek.typeText("dakkapel")
        XCTAssertTrue(element(app, beginMet: "Dakkapel schoonmaken").waitForExistence(timeout: 5))
    }
}

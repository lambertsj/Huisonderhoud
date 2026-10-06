#if DEBUG
import SwiftData
import SwiftUI

/// Voorbeelddata voor previews: een woning met het volledige eerste schema.
@MainActor
enum Voorbeeld {
    nonisolated static let nu = Date(timeIntervalSince1970: 1_790_000_000) // 22 sep 2026

    static var dienst: Huisdienst {
        // swiftlint:disable:next force_try
        Huisdienst(catalogus: try! Catalogus.gebundeld())
    }

    /// Container met woning, schema en één afgevinkte klus.
    static func container(metSchema: Bool = true, nu: Date = Voorbeeld.nu) -> ModelContainer {
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: Schema(Bijlage.schema), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        if metSchema {
            let context = container.mainContext
            let woning = dienst.maakSchema(kenmerken: Kenmerken.tags(voorKeuzes: Set(Kenmerken.keuzes.map(\.id))), context: context, nu: nu)
            if let taak = woning.alleTaken.first {
                let u = Uitvoering(datum: nu, titelSnapshot: dienst.catalogus.taak(met: taak.catalogusID ?? "")?.titel ?? "", categorieSnapshot: "Veiligheid", uitvoerder: .zelf, taak: taak, woning: woning)
                context.insert(u)
            }
        }
        return container
    }
}

extension Voorbeeld {
    /// Rijke data voor App Store-screenshots: een bewoond huis met een gevuld Boekje.
    /// Alleen via het launchargument `-screenshotdata`.
    static func screenshotContainer() -> ModelContainer {
        let container = self.container(metSchema: false)
        let context = container.mainContext
        let kal = Calendar(identifier: .gregorian)
        func d(_ j: Int, _ m: Int, _ dag: Int) -> Date { kal.date(from: DateComponents(year: j, month: m, day: dag, hour: 12))! }

        let kenmerken = Kenmerken.tags(voorKeuzes: ["cv-ketel", "schuin-dak", "houten-kozijnen", "tuin", "boiler", "zonnepanelen", "afzuigkap"])
        let dienst = self.dienst
        let woning = dienst.maakSchema(kenmerken: kenmerken, context: context, nu: Date())
        woning.naam = "Huis aan de Dijk"
        woning.bouwjaar = 1985
        woning.woningtype = "Tussenwoning"

        let apparaat = Apparaat(soort: "Cv-ketel", merk: "Remeha", model: "Avanta 28c", serienummer: "RE-4471-2019",
                                aangeschaftOp: d(2019, 5, 14), garantieTot: d(2029, 5, 14), installateurNaam: "Installatie De Boer", woning: woning)
        context.insert(apparaat)
        context.insert(Apparaat(soort: "Boiler", merk: "Atag", model: "Q120", garantieTot: d(2027, 2, 1), woning: woning))

        func taak(_ id: String) -> Taak? { woning.alleTaken.first { $0.catalogusID == id } }
        let gedaan: [(String, Date, Uitvoerder, String, String)] = [
            ("veiligheid-rookmelders-testen", d(2026, 9, 14), .zelf, "", "Batterij in de gang vervangen."),
            ("verwarming-cv-onderhoud", d(2025, 10, 2), .vakman, "Installatie De Boer", "Ketel gereinigd, waterdruk 1,8 bar."),
            ("dak-goten-najaar", d(2025, 11, 8), .zelf, "", "Veel bladeren bij de hoek, nu schoon."),
            ("water-boiler-veiligheidsgroep", d(2026, 3, 21), .zelf, "", ""),
            ("ramen-kitnaden-buiten", d(2026, 4, 18), .zelf, "", "Kitnaad van het badkamerraam vernieuwd."),
            ("ventilatie-filters-mechanisch", d(2026, 6, 5), .zelf, "", ""),
            ("apparaten-wasmachine-filter", d(2026, 8, 30), .zelf, "", ""),
        ]
        for (id, datum, door, naam, notitie) in gedaan {
            guard let t = taak(id) else { continue }
            let u = dienst.vinkAf(t, datum: datum, uitvoerder: door, notitie: notitie, context: context)
            u.uitvoerderNaam = naam.isEmpty ? nil : naam
        }
        // Wat er nu aan de beurt is.
        let planning: [(String, Date)] = [
            ("veiligheid-aardlekschakelaar", d(2026, 9, 18)), ("water-kranen-douchekop-ontkalken", d(2026, 9, 25)),
            ("veiligheid-co-melder", d(2026, 10, 9)), ("verwarming-cv-waterdruk", d(2026, 10, 12)),
            ("verwarming-radiatoren-ontluchten", d(2026, 10, 15)), ("algemeen-winter-voorbereiding", d(2026, 10, 24)),
        ]
        for (id, datum) in planning { taak(id)?.volgendeDatum = datum }
        try? context.save()
        return container
    }
}

#Preview("Onboarding") {
    OnboardingView(bezig: .constant(false))
        .environment(Voorbeeld.dienst)
        .modelContainer(Voorbeeld.container(metSchema: false))
}

#Preview("Nu, licht") {
    HoofdView()
        .environment(Voorbeeld.dienst)
        .modelContainer(Voorbeeld.container())
        .environment(\.nu, { Voorbeeld.nu })
}

#Preview("Nu, donker") {
    HoofdView()
        .environment(Voorbeeld.dienst)
        .modelContainer(Voorbeeld.container())
        .environment(\.nu, { Voorbeeld.nu })
        .preferredColorScheme(.dark)
}

#Preview("Nu, grootste tekst") {
    HoofdView()
        .environment(Voorbeeld.dienst)
        .modelContainer(Voorbeeld.container())
        .environment(\.nu, { Voorbeeld.nu })
        .dynamicTypeSize(.accessibility5)
}
#endif

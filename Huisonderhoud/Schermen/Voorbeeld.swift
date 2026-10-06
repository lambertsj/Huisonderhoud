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

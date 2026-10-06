import SwiftData
import SwiftUI

/// Eerste start: onboarding. Daarna de vier tabs.
struct WortelView: View {
    @Query private var woningen: [Woning]
    @State private var onboardingBezig = false

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.scenePhase) private var fase

    var body: some View {
        Group {
            if woningen.isEmpty || onboardingBezig {
                OnboardingView(bezig: $onboardingBezig)
            } else {
                HoofdView()
            }
        }
        .tint(Color.brand)
        .task(id: fase) {
            guard fase == .active, !onboardingBezig else { return }
            await dienst.herplanMeldingen(taken: woningen.flatMap(\.alleTaken))
        }
    }
}

struct CatalogusFoutView: View {
    let fout: Error

    var body: some View {
        Scherm {
            Schermkop(titel: "Huisonderhoud",
                      subregel: "De onderhoudstaken konden niet worden geladen. Installeer de app opnieuw of meld dit via de broncode. Er gaat niets verloren: je eigen gegevens blijven op je telefoon.",
                      subregelIsUitleg: true)
            Text("\(String(describing: fout))")
                .tekststijl(.klein)
                .foregroundStyle(Color.inkMuted)
        }
    }
}

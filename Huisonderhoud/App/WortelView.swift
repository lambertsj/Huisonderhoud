import SwiftData
import SwiftUI

/// Eerste start: onboarding. Daarna de vier tabs.
struct WortelView: View {
    @Query private var woningen: [Woning]
    @State private var onboardingBezig = false

    @Environment(Huisdienst.self) private var dienst
    @Environment(\.modelContext) private var context
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
            for woning in woningen { dienst.synchroniseer(woning: woning, context: context) }
            await dienst.herplanMeldingen(taken: woningen.flatMap(\.alleTaken))
        }
    }
}

/// Als de app niet kan starten: wat er is en wat je kunt doen. Je gegevens worden niet aangeraakt.
struct StartfoutView: View {
    let tekst: String

    var body: some View {
        Scherm {
            Schermkop(titel: "Huisonderhoud start niet",
                      subregel: "Je gegevens zijn niet gewijzigd. Sluit de app helemaal af en open hem opnieuw. Lukt dat niet, installeer de app dan opnieuw. Een export uit Huis kun je daarna importeren.",
                      subregelIsUitleg: true)
            Text(tekst)
                .tekststijl(.klein)
                .foregroundStyle(Color.inkMuted)
        }
    }
}

import Foundation
import UserNotifications

/// Dunne laag om `UNUserNotificationCenter`. De keuzes zitten in `Meldingplanner`.
@MainActor
final class MeldingCentrum {
    static let gedeeld = MeldingCentrum()

    private let center = UNUserNotificationCenter.current()
    private static let schakelaarSleutel = "herinneringenAan"

    /// Globale schakelaar. Staat uit tot de gebruiker in de onboarding toestemming geeft.
    var herinneringenAan: Bool {
        get { UserDefaults.standard.bool(forKey: Self.schakelaarSleutel) }
        set { UserDefaults.standard.set(newValue, forKey: Self.schakelaarSleutel) }
    }

    func autorisatiestatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Vraagt toestemming (zonder badges) en onthoudt het antwoord in de schakelaar.
    func toestemmingVragen() async -> Bool {
        let toegestaan = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        herinneringenAan = toegestaan
        return toegestaan
    }

    /// Plant alle meldingen opnieuw: eerst de oude weg, dan de eerstvolgende ~50.
    func herplan(_ kandidaten: [MeldingKandidaat], nu: Date = Date(), kalender: Calendar = .current) async {
        let bestaand = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Meldingplanner.identifierVoorvoegsel) }
        center.removePendingNotificationRequests(withIdentifiers: bestaand)
        guard herinneringenAan, await autorisatiestatus() == .authorized else { return }

        for melding in Meldingplanner.plan(kandidaten, nu: nu, kalender: kalender) {
            let inhoud = UNMutableNotificationContent()
            inhoud.title = melding.titel
            inhoud.body = "Deze klus is aan de beurt."
            inhoud.sound = .default
            let delen = kalender.dateComponents([.year, .month, .day, .hour, .minute], from: melding.moment)
            let trigger = UNCalendarNotificationTrigger(dateMatching: delen, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: melding.identifier, content: inhoud, trigger: trigger))
        }
    }
}

extension Taak {
    /// De velden die de meldingplanner nodig heeft.
    func meldingKandidaat(titel: String) -> MeldingKandidaat {
        MeldingKandidaat(id: id, titel: titel, volgendeDatum: volgendeDatum, isActief: isActief, herinneringAan: herinneringAan)
    }
}

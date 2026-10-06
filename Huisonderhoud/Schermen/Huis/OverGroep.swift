import SwiftUI

/// Over: de BasisApps-afspraken in gewone taal, links, licentie en versie.
struct OverGroep: View {
    static let basisAppsURL = URL(string: "https://basisapps.nl")!
    /// Placeholder tot Jeroen de definitieve URL kiest (zie TODO.md).
    static let broncodeURL = URL(string: "https://github.com/lambertsj/Huisonderhoud")!

    private let afspraken: [(titel: String, uitleg: String)] = [
        ("Echt gratis", "Geen abonnement, geen aankopen, geen betaalmuur. Ook het pdf-dossier is gratis."),
        ("Reclamevrij", "Geen advertenties, banners of pop-ups."),
        ("Geen trackers, geen account", "Geen analyse, geen inlog, geen server. De app doet geen enkel netwerkverzoek."),
        ("Je gegevens blijven bij jou", "Alles staat op je telefoon. Met Exporteren neem je het mee."),
        ("Open source", "De code is openbaar. Iedereen mag meekijken en verbeteren."),
    ]

    var body: some View {
        Groep(kop: "Over") {
            Text("Huisonderhoud is een BasisApp: een gratis, open Nederlandse app. Dit zijn de afspraken.")
                .tekststijl(.body)
                .foregroundStyle(Color.ink)
                .padding(Ruimte.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(afspraken, id: \.titel) { afspraak in
                Haarlijn()
                Lijstrij(titel: afspraak.titel, uitleg: afspraak.uitleg)
            }
            Haarlijn()
            linkRij("Basis Certified", url: Self.basisAppsURL, waarde: "basisapps.nl")
            Haarlijn()
            linkRij("Broncode", url: Self.broncodeURL, waarde: "github.com")
            Haarlijn()
            Lijstrij(titel: "Licentie", waarde: "MIT voor de code")
            Haarlijn()
            Lijstrij(titel: "Versie", waarde: versie)
        }
    }

    private func linkRij(_ titel: String, url: URL, waarde: String) -> some View {
        Link(destination: url) {
            Lijstrij(titel: titel, waarde: waarde)
        }
        .buttonStyle(RijKnopStijl())
        .accessibilityHint("Opent in de browser")
    }

    private var versie: String {
        let info = Bundle.main.infoDictionary
        let versie = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let bouw = info?["CFBundleVersion"] as? String ?? "1"
        return "\(versie) (\(bouw))"
    }
}

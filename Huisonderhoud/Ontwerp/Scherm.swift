import SwiftUI

/// Het kader van elk scherm: één bladzijde op `surface`, 16 pt schermrand.
struct Scherm<Inhoud: View>: View {
    private let inhoud: Inhoud

    init(@ViewBuilder inhoud: () -> Inhoud) {
        self.inhoud = inhoud()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Ruimte.xl) { inhoud }
                .padding(.horizontal, Ruimte.schermrand)
                .padding(.top, Ruimte.l)
                .padding(.bottom, Ruimte.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.surface.ignoresSafeArea())
        .scrollBounceBehavior(.basedOnSize)
    }
}

/// Titel en subregel van een scherm. Eén titel per scherm.
struct Schermkop: View {
    let titel: String
    var subregel: String?
    var subregelIsUitleg = false

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.s) {
            Text(titel)
                .tekststijl(.titelGroot)
                .foregroundStyle(Color.ink)
                .accessibilityAddTraits(.isHeader)
            if let subregel {
                Text(subregel)
                    .tekststijl(subregelIsUitleg ? .uitleg : .klein)
                    .foregroundStyle(Color.inkMuted)
            }
        }
    }
}

/// Groepskop boven een blad.
struct Groepskop: View {
    let tekst: String

    init(_ tekst: String) { self.tekst = tekst }

    var body: some View {
        Text(tekst)
            .tekststijl(.kop)
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Een groep: kop met daaronder het blad.
struct Groep<Inhoud: View>: View {
    let kop: String
    @ViewBuilder let inhoud: Inhoud

    var body: some View {
        VStack(alignment: .leading, spacing: Ruimte.m) {
            Groepskop(kop)
            Blad { inhoud }
        }
    }
}

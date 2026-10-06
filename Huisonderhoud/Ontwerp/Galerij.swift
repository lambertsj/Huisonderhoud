#if DEBUG
import SwiftUI

/// Alle ontwerpcomponenten op één scherm, voor previews.
struct Ontwerpgalerij: View {
    private let datum = Date(timeIntervalSince1970: 1_790_000_000)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Ruimte.xl) {
                Text("Nu aan de beurt").tekststijl(.titelGroot).foregroundStyle(Color.ink)
                Text("Dinsdag 6 oktober").tekststijl(.klein).foregroundStyle(Color.inkMuted)

                Text("Te laat").tekststijl(.kop).foregroundStyle(Color.ink)
                Blad {
                    TaakRij(titel: "Dakgoten reinigen", status: .telaat, wanneer: "sinds september",
                            uitvoering: .zelfOfVakman, duur: 90)
                    Haarlijn()
                    TaakRij(titel: "Rookmelders testen", status: .nu, wanneer: "", uitvoering: .zelf, duur: 5)
                    Haarlijn()
                    TaakRij(titel: "Cv-ketel laten onderhouden", status: .later, wanneer: "In november",
                            uitvoering: .vakman, duur: 60)
                    Haarlijn()
                    TaakRij(titel: "Rookmelders testen", status: .gedaan, wanneer: "Elke maand",
                            stempel: (datum, .zelf))
                }

                Waarschuwing(tekst: "Werk nooit aan gasleidingen of elektra als je niet weet wat je doet.")

                VStack(spacing: Ruimte.m) {
                    Button("Afvinken") {}.buttonStyle(.primair)
                    Button("Foto toevoegen") {}.buttonStyle(.secundair)
                    Button("Notitie toevoegen") {}.buttonStyle(.tekst)
                }
            }
            .padding(Ruimte.schermrand)
        }
        .background(Color.surface)
    }
}

#Preview("Licht") { Ontwerpgalerij() }
#Preview("Donker") { Ontwerpgalerij().preferredColorScheme(.dark) }
#Preview("Grootste tekst") { Ontwerpgalerij().dynamicTypeSize(.accessibility5) }
#endif

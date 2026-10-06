import SwiftUI

struct SchemaScherm: View {
    var body: some View { Scherm { Schermkop(titel: "Schema") } }
}

struct BoekjeScherm: View {
    var body: some View { Scherm { Schermkop(titel: "Boekje", subregel: "Alles wat je aan je huis hebt gedaan") } }
}

struct HuisScherm: View {
    var body: some View { Scherm { Schermkop(titel: "Huis") } }
}

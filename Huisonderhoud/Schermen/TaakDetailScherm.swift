import SwiftUI

struct TaakDetailScherm: View {
    let taak: Taak
    @Environment(Huisdienst.self) private var dienst

    var body: some View {
        Scherm {
            Schermkop(titel: taak.inhoud(in: dienst.catalogus).titel)
        }
    }
}

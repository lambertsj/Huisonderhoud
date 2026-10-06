import SwiftUI
import UIKit

/// Kleine foto's van de gebruiker. Optioneel met een verwijderknop (44 x 44 pt).
struct Fotostrook: View {
    let fotos: [Data]
    var verwijder: ((Int) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Ruimte.s) {
                ForEach(Array(fotos.enumerated()), id: \.offset) { index, data in
                    ZStack(alignment: .topTrailing) {
                        if let beeld = UIImage(data: data) {
                            Image(uiImage: beeld)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: Hoek.stempel))
                                .overlay(RoundedRectangle(cornerRadius: Hoek.stempel).strokeBorder(Color.line, lineWidth: 1))
                                .accessibilityLabel("Foto \(index + 1)")
                        }
                        if let verwijder {
                            Button {
                                verwijder(index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(Color.onBrand, Color.ink)
                                    .frame(width: Ruimte.aanraakminimum, height: Ruimte.aanraakminimum)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Foto \(index + 1) verwijderen")
                        }
                    }
                }
            }
            .padding(.vertical, Ruimte.xs)
        }
    }
}

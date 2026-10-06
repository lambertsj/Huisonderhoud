import Foundation
import ImageIO
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Foto's worden bij het opslaan verkleind: maximaal 2000 px lange zijde, JPEG ongeveer 0,8.
enum Fotoverkleiner {
    static let maximaleZijde = 2000
    static let kwaliteit = 0.8

    /// nil als de data geen afbeelding is.
    static func verklein(_ data: Data, maximaleZijde: Int = Fotoverkleiner.maximaleZijde, kwaliteit: Double = Fotoverkleiner.kwaliteit) -> Data? {
        guard let bron = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let opties: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximaleZijde,
        ]
        guard let beeld = CGImageSourceCreateThumbnailAtIndex(bron, 0, opties as CFDictionary) else { return nil }
        let uitvoer = NSMutableData()
        guard let doel = CGImageDestinationCreateWithData(uitvoer, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(doel, beeld, [kCGImageDestinationLossyCompressionQuality: kwaliteit] as CFDictionary)
        guard CGImageDestinationFinalize(doel) else { return nil }
        return uitvoer as Data
    }

    /// Afmetingen in pixels, voor tests.
    static func afmetingen(_ data: Data) -> (breedte: Int, hoogte: Int)? {
        guard let bron = CGImageSourceCreateWithData(data as CFData, nil),
              let eigenschappen = CGImageSourceCopyPropertiesAtIndex(bron, 0, nil) as? [CFString: Any],
              let b = eigenschappen[kCGImagePropertyPixelWidth] as? Int,
              let h = eigenschappen[kCGImagePropertyPixelHeight] as? Int else { return nil }
        return (b, h)
    }
}

extension Fotoverkleiner {
    /// Laadt en verkleint gekozen foto's. `mislukt` telt de foto's die niet te lezen waren.
    static func laad(_ items: [PhotosPickerItem]) async -> (fotos: [Data], mislukt: Int) {
        var fotos: [Data] = []
        var mislukt = 0
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let verkleind = verklein(data) {
                fotos.append(verkleind)
            } else {
                mislukt += 1
            }
        }
        return (fotos, mislukt)
    }

    static func foutTekst(mislukt: Int) -> String? {
        switch mislukt {
        case 0: nil
        case 1: "Die foto kon niet worden geladen. Kies een andere foto."
        default: "\(mislukt) foto's konden niet worden geladen. Kies andere foto's."
        }
    }
}

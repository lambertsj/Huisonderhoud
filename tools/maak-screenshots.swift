// Zet ruwe simulatoropnames (1320 x 2868) om in App Store-screenshots met een kop.
// Gebruik: swiftc -O tools/maak-screenshots.swift -o /tmp/maak-screenshots && /tmp/maak-screenshots <ruw-map> <uit-map>
import AppKit
import ImageIO

let args = CommandLine.arguments
let ruw = URL(fileURLWithPath: args[1]), uit = URL(fileURLWithPath: args[2])
let fonts = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Huisonderhoud/Resources/Fonts")
for f in ["SchibstedGrotesk-Bold.ttf", "SchibstedGrotesk-Regular.ttf"] {
    CTFontManagerRegisterFontsForURL(fonts.appendingPathComponent(f) as CFURL, .process, nil)
}

func kleur(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let surface = kleur(0xECEEE8), ink = kleur(0x14261D), gedempt = kleur(0x56605A), lijn = kleur(0xC9CEC4)

let schermen: [(String, String, String)] = [
    ("1-nu", "Weet wat er aan je huis moet gebeuren", "Je schema, per maand gesorteerd."),
    ("2-detail", "Elke klus met uitleg en een waarschuwing waar het ertoe doet", "Met duur, wie het doet en wat je moet weten."),
    ("3-boekje", "Elke afgevinkte klus krijgt een stempel", "Datum, uitvoerder, notitie en foto in je Boekje."),
    ("4-schema", "Een schema op maat van jouw huis", "Alle taken per categorie, met zoekveld."),
    ("5-huis", "Apparaten, garantie en typeplaatjes bij elkaar", "Merk, serienummer en een foto van het typeplaatje."),
    ("6-onboarding", "Vink aan wat bij je huis hoort", "Gratis, reclamevrij en zonder account."),
]

let breedte = 1320, hoogte = 2868
try? FileManager.default.createDirectory(at: uit, withIntermediateDirectories: true)

for (naam, kop, sub) in schermen {
    guard let beeld = NSImage(contentsOf: ruw.appendingPathComponent("\(naam).png")) else { print("mist: \(naam)"); continue }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: breedte, pixelsHigh: hoogte, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: breedte, height: hoogte)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    surface.setFill()
    NSRect(x: 0, y: 0, width: breedte, height: hoogte).fill()

    let marge: CGFloat = 110
    let tekstBreedte = CGFloat(breedte) - 2 * marge
    let stijl = NSMutableParagraphStyle()
    stijl.lineBreakMode = .byWordWrapping
    stijl.lineSpacing = 6
    let kopTekst = NSAttributedString(string: kop, attributes: [
        .font: NSFont(name: "SchibstedGrotesk-Bold", size: 96) ?? .boldSystemFont(ofSize: 96),
        .foregroundColor: ink, .kern: -1.0, .paragraphStyle: stijl])
    let kopRect = kopTekst.boundingRect(with: NSSize(width: tekstBreedte, height: 2000), options: [.usesLineFragmentOrigin])
    let bovenkant = CGFloat(hoogte) - 150
    kopTekst.draw(with: NSRect(x: marge, y: bovenkant - ceil(kopRect.height), width: tekstBreedte, height: ceil(kopRect.height)),
                  options: [.usesLineFragmentOrigin])

    let subTekst = NSAttributedString(string: sub, attributes: [
        .font: NSFont(name: "SchibstedGrotesk-Regular", size: 52) ?? .systemFont(ofSize: 52), .foregroundColor: gedempt])
    let subY = bovenkant - ceil(kopRect.height) - 36 - 64
    subTekst.draw(with: NSRect(x: marge, y: subY, width: tekstBreedte, height: 64), options: [.usesLineFragmentOrigin])

    // Het scherm, met afgeronde hoeken en een rand van wat lucht eronder.
    let schermBreedte: CGFloat = 930
    let schermHoogte = schermBreedte * CGFloat(2868) / 1320
    let x = (CGFloat(breedte) - schermBreedte) / 2
    let top = subY - 70
    let rect = NSRect(x: x, y: top - schermHoogte, width: schermBreedte, height: schermHoogte)
    let pad = NSBezierPath(roundedRect: rect, xRadius: 70, yRadius: 70)
    NSGraphicsContext.saveGraphicsState()
    pad.addClip()
    beeld.draw(in: rect)
    NSGraphicsContext.restoreGraphicsState()
    lijn.setStroke()
    pad.lineWidth = 4
    pad.stroke()

    NSGraphicsContext.restoreGraphicsState()
    // Zonder alfakanaal opslaan, zoals de App Store het wil.
    let plat = CGContext(data: nil, width: breedte, height: hoogte, bitsPerComponent: 8, bytesPerRow: 0,
                         space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    plat.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: breedte, height: hoogte))
    let doel = CGImageDestinationCreateWithURL(uit.appendingPathComponent("\(naam).png") as CFURL, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(doel, plat.makeImage()!, nil)
    CGImageDestinationFinalize(doel)
    print("klaar: \(naam)")
}

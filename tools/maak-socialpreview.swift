// Social preview voor GitHub (1280 x 640): icoon, naam en één regel, op brand-groen.
// Gebruik: swiftc -O tools/maak-socialpreview.swift -o /tmp/sp && /tmp/sp <icoon.png> <uit.png>
import AppKit
import ImageIO

let fonts = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Huisonderhoud/Resources/Fonts")
for f in ["SchibstedGrotesk-Bold.ttf", "SchibstedGrotesk-Regular.ttf"] { CTFontManagerRegisterFontsForURL(fonts.appendingPathComponent(f) as CFURL, .process, nil) }
let groen = NSColor(srgbRed: 0x1F / 255, green: 0x5C / 255, blue: 0x43 / 255, alpha: 1)
let papier = NSColor(srgbRed: 0xF7 / 255, green: 0xF8 / 255, blue: 0xF4 / 255, alpha: 1)
let (w, h) = (1280, 640)
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                           isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
groen.setFill(); NSRect(x: 0, y: 0, width: w, height: h).fill()
let icoon = NSImage(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))!
let klem = NSBezierPath(roundedRect: NSRect(x: 110, y: 120, width: 400, height: 400), xRadius: 90, yRadius: 90)
NSGraphicsContext.saveGraphicsState(); klem.addClip(); icoon.draw(in: NSRect(x: 110, y: 120, width: 400, height: 400)); NSGraphicsContext.restoreGraphicsState()
func tekst(_ s: String, _ font: String, _ maat: CGFloat, _ y: CGFloat) {
    NSAttributedString(string: s, attributes: [.font: NSFont(name: font, size: maat)!, .foregroundColor: papier])
        .draw(in: NSRect(x: 590, y: y, width: 680, height: maat * 1.4))
}
tekst("Huisonderhoud", "SchibstedGrotesk-Bold", 78, 300)
tekst("Weet altijd wat er aan je huis", "SchibstedGrotesk-Regular", 38, 235)
tekst("moet gebeuren. Gratis en open.", "SchibstedGrotesk-Regular", 38, 190)
NSGraphicsContext.restoreGraphicsState()
let plat = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
plat.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: w, height: h))
let d = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(d, plat.makeImage()!, nil); CGImageDestinationFinalize(d)

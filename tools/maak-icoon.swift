// Maakt het app-icoon: de Stempel op brand-groen. Drie kleuren uit de kleurenset.
// Gebruik: swiftc -O tools/maak-icoon.swift -o /tmp/maak-icoon && /tmp/maak-icoon <uitvoer.png>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func kleur(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: 1)
}
let groen = kleur(0x1F5C43)   // brand
let papier = kleur(0xF7F8F4)  // surfaceRaised
let blauw = kleur(0x2A4B8D)   // stempelblauw

let maat = 1024
let ctx = CGContext(data: nil, width: maat, height: maat, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
ctx.setFillColor(groen)
ctx.fill(CGRect(x: 0, y: 0, width: maat, height: maat))

ctx.translateBy(x: 512, y: 512)
ctx.rotate(by: 2.5 * .pi / 180) // 2,5 graden tegen de klok in (CG: y omhoog)

let b: CGFloat = 640, h: CGFloat = 560
let buiten = CGRect(x: -b / 2, y: -h / 2, width: b, height: h)
ctx.addPath(CGPath(roundedRect: buiten, cornerWidth: 14, cornerHeight: 14, transform: nil))
ctx.setFillColor(papier)
ctx.fillPath()

ctx.setStrokeColor(blauw)
ctx.setLineWidth(24)
ctx.addPath(CGPath(roundedRect: buiten.insetBy(dx: 12 + 28, dy: 12 + 28), cornerWidth: 8, cornerHeight: 8, transform: nil))
ctx.strokePath()
ctx.setLineWidth(11)
ctx.addPath(CGPath(roundedRect: buiten.insetBy(dx: 12 + 28 + 40, dy: 12 + 28 + 40), cornerWidth: 4, cornerHeight: 4, transform: nil))
ctx.strokePath()

// Vinkje
ctx.setLineWidth(62)
ctx.setLineCap(.square)
ctx.setLineJoin(.miter)
ctx.move(to: CGPoint(x: -135, y: -5))
ctx.addLine(to: CGPoint(x: -35, y: -105))
ctx.addLine(to: CGPoint(x: 150, y: 95))
ctx.strokePath()

let uit = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(uit as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)

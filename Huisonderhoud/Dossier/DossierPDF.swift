import CoreTransferable
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Het onderhoudsdossier als A4-pdf. Op papier altijd het lichte thema, dezelfde
/// lettertypen en kleuren als de app. Geen advertentie, geen watermerk, geen logo.
enum DossierPDF {
    static let pagina = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
    static let marge: CGFloat = 56

    static func maak(_ inhoud: DossierInhoud) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: pagina, format: {
            let f = UIGraphicsPDFRendererFormat()
            f.documentInfo = [
                kCGPDFContextTitle as String: "Onderhoudsdossier \(inhoud.woningnaam)",
                kCGPDFContextCreator as String: "Huisonderhoud",
            ]
            return f
        }())
        return renderer.pdfData { context in
            var schrijver = Schrijver(context: context, inhoud: inhoud)
            schrijver.schrijf()
        }
    }

    // MARK: Opmaak

    private enum Papier {
        static let licht = UITraitCollection(userInterfaceStyle: .light)

        static func kleur(_ token: Kleurtoken) -> UIColor {
            let bundle = Bundle(for: HuisonderhoudBundleAnker.self)
            return UIColor(named: token.rawValue, in: bundle, compatibleWith: licht)?.resolvedColor(with: licht) ?? .black
        }

        static var ink: UIColor { kleur(.ink) }
        static var gedempt: UIColor { kleur(.inkMuted) }
        static var haarlijn: UIColor { kleur(.line) }
        static var stempel: UIColor { kleur(.stempelblauw) }
        static var merk: UIColor { kleur(.brand) }

        static func schibsted(_ grootte: CGFloat, _ gewicht: Font.Weight = .regular) -> UIFont {
            let naam = Tekststijl.postScriptNaam(familie: "schibsted", gewicht: gewicht)
            return UIFont(name: naam, size: grootte) ?? .systemFont(ofSize: grootte, weight: gewicht == .bold ? .bold : (gewicht == .semibold ? .semibold : .regular))
        }

        static func barlow(_ grootte: CGFloat, _ gewicht: Font.Weight = .semibold) -> UIFont {
            let naam = Tekststijl.postScriptNaam(familie: "barlow", gewicht: gewicht)
            return UIFont(name: naam, size: grootte) ?? .systemFont(ofSize: grootte, weight: .semibold)
        }
    }

    private struct Schrijver {
        let context: UIGraphicsPDFRendererContext
        let inhoud: DossierInhoud
        var y: CGFloat = marge
        var paginanummer = 0

        init(context: UIGraphicsPDFRendererContext, inhoud: DossierInhoud) {
            self.context = context
            self.inhoud = inhoud
        }

        var breedte: CGFloat { pagina.width - 2 * marge }
        var onderkant: CGFloat { pagina.height - marge - 16 }

        mutating func schrijf() {
            voorblad()
            nieuwePagina()
            if !inhoud.apparaten.isEmpty { apparaten() }
            logboek()
        }

        // MARK: Pagina's

        mutating func nieuwePagina() {
            context.beginPage()
            paginanummer += 1
            y = marge
            if paginanummer > 1 {
                let tekst = NSAttributedString(string: "\(inhoud.woningnaam), onderhoudsdossier. Pagina \(paginanummer)",
                                               attributes: [.font: Papier.schibsted(9, .medium), .foregroundColor: Papier.gedempt])
                tekst.draw(at: CGPoint(x: marge, y: pagina.height - marge + 6))
            }
        }

        mutating func ruimte(_ hoogte: CGFloat) {
            if y + hoogte > onderkant { nieuwePagina() }
        }

        // MARK: Voorblad

        mutating func voorblad() {
            context.beginPage()
            paginanummer = 1
            y = 190
            teken("Onderhoudsdossier", font: Papier.schibsted(38, .bold), kleur: Papier.ink)
            y += 10
            teken(inhoud.woningnaam, font: Papier.schibsted(24, .bold), kleur: Papier.merk)
            y += 14
            var regels: [String] = []
            if let bouwjaar = inhoud.bouwjaar { regels.append("Bouwjaar \(bouwjaar)") }
            if !inhoud.woningtype.isEmpty { regels.append(inhoud.woningtype) }
            for regel in regels { teken(regel, font: Papier.schibsted(14), kleur: Papier.ink) }
            y += 24
            haarlijn()
            y += 16
            teken("Dossier van \(Datumopmaak.kort(inhoud.datum, kalender: inhoud.kalender))", font: Papier.schibsted(14, .semibold), kleur: Papier.ink)
            let aantal = inhoud.aantalRegels
            teken(aantal == 1 ? "1 afgevinkte klus" : "\(aantal) afgevinkte klussen", font: Papier.schibsted(14), kleur: Papier.gedempt)
            if !inhoud.apparaten.isEmpty {
                teken(inhoud.apparaten.count == 1 ? "1 apparaat" : "\(inhoud.apparaten.count) apparaten", font: Papier.schibsted(14), kleur: Papier.gedempt)
            }
            if let eerste = inhoud.jaren.last?.regels.last, let laatste = inhoud.jaren.first?.regels.first {
                teken("Van \(Datumopmaak.kort(eerste.datum, kalender: inhoud.kalender)) tot \(Datumopmaak.kort(laatste.datum, kalender: inhoud.kalender))",
                      font: Papier.schibsted(14), kleur: Papier.gedempt)
            }
        }

        // MARK: Apparaten

        mutating func apparaten() {
            kop("Apparaten")
            for apparaat in inhoud.apparaten {
                var titel = [apparaat.soort, [apparaat.merk, apparaat.model].filter { !$0.isEmpty }.joined(separator: " ")]
                    .filter { !$0.isEmpty }.joined(separator: ", ")
                if titel.isEmpty { titel = "Apparaat" }
                var details: [String] = []
                if !apparaat.serienummer.isEmpty { details.append("Serienummer: \(apparaat.serienummer)") }
                if let d = apparaat.aangeschaft { details.append("Aangeschaft: \(Datumopmaak.kort(d, kalender: inhoud.kalender))") }
                if let d = apparaat.garantieTot { details.append("Garantie tot: \(Datumopmaak.kort(d, kalender: inhoud.kalender))") }
                if !apparaat.installateur.isEmpty { details.append("Installateur: \(apparaat.installateur)") }
                let hoogte = meet(titel, font: Papier.schibsted(12, .semibold), breedte: breedte)
                    + details.reduce(0) { $0 + meet($1, font: Papier.schibsted(11), breedte: breedte) } + 16
                ruimte(hoogte)
                teken(titel, font: Papier.schibsted(12, .semibold), kleur: Papier.ink)
                for detail in details { teken(detail, font: Papier.schibsted(11), kleur: Papier.gedempt) }
                y += 8
                haarlijn()
                y += 8
            }
            y += 12
        }

        // MARK: Logboek

        mutating func logboek() {
            ruimte(80)
            kop("Logboek")
            if inhoud.jaren.isEmpty {
                teken("Er is nog niets afgevinkt.", font: Papier.schibsted(12), kleur: Papier.gedempt)
                return
            }
            for jaar in inhoud.jaren {
                ruimte(70)
                teken(String(jaar.jaar), font: Papier.schibsted(15, .bold), kleur: Papier.ink)
                y += 6
                haarlijn()
                for regel in jaar.regels { schrijf(regel) }
                y += 14
            }
        }

        mutating func schrijf(_ regel: DossierInhoud.Regel) {
            let datumBreedte: CGFloat = 78
            let vignetBreedte: CGFloat = 70
            let x = marge + datumBreedte + 8
            let tekstBreedte = breedte - datumBreedte - 8 - vignetBreedte - 8
            let door = regel.uitvoerderNaam.isEmpty ? regel.uitvoerder.label.lowercased() : "\(regel.uitvoerder.label.lowercased()), \(regel.uitvoerderNaam)"
            let titelFont = Papier.schibsted(12, .semibold), metaFont = Papier.schibsted(10.5), notitieFont = Papier.schibsted(10.5)
            let foto: CGFloat = 52
            var hoogte = meet(regel.titel, font: titelFont, breedte: tekstBreedte) + 2 + meet("Door \(door)", font: metaFont, breedte: tekstBreedte)
            if !regel.notitie.isEmpty { hoogte += 3 + meet(regel.notitie, font: notitieFont, breedte: tekstBreedte) }
            if !regel.fotos.isEmpty { hoogte += 6 + foto }
            hoogte = max(hoogte, 34) + 16
            ruimte(hoogte)

            let startY = y + 8
            NSAttributedString(string: Datumopmaak.kort(regel.datum, kalender: inhoud.kalender),
                               attributes: [.font: Papier.schibsted(10.5, .medium), .foregroundColor: Papier.gedempt])
                .draw(at: CGPoint(x: marge, y: startY))

            let linksBoven = y
            y = startY
            teken(regel.titel, font: titelFont, kleur: Papier.ink, x: x, breedte: tekstBreedte)
            y += 2
            teken("Door \(door)", font: metaFont, kleur: Papier.gedempt, x: x, breedte: tekstBreedte)
            if !regel.notitie.isEmpty {
                y += 3
                teken(regel.notitie, font: notitieFont, kleur: Papier.ink, x: x, breedte: tekstBreedte)
            }
            if !regel.fotos.isEmpty {
                y += 6
                var fx = x
                for data in regel.fotos {
                    guard let beeld = UIImage(data: data) else { continue }
                    let verhouding = beeld.size.width / max(beeld.size.height, 1)
                    let b = min(foto * verhouding, 90)
                    let rect = CGRect(x: fx, y: y, width: b, height: foto)
                    beeld.draw(in: rect)
                    Papier.haarlijn.setStroke()
                    UIBezierPath(rect: rect).stroke()
                    fx += b + 6
                }
                y += foto
            }
            vignet(voor: regel, in: CGRect(x: pagina.width - marge - vignetBreedte, y: startY - 2, width: vignetBreedte, height: 34))
            y = max(y, linksBoven + hoogte - 8) + 8
            haarlijn()
        }

        /// Klein stempelvignet in `stempelblauw`: dubbele rand, 2,5 graden gedraaid.
        func vignet(voor regel: DossierInhoud.Regel, in rect: CGRect) {
            let cg = context.cgContext
            cg.saveGState()
            cg.translateBy(x: rect.midX, y: rect.midY)
            cg.rotate(by: -2.5 * .pi / 180)
            let doos = CGRect(x: -rect.width / 2 + 4, y: -rect.height / 2, width: rect.width - 8, height: rect.height)
            Papier.stempel.setStroke()
            let buiten = UIBezierPath(roundedRect: doos, cornerRadius: 1)
            buiten.lineWidth = 1
            buiten.stroke()
            let binnen = UIBezierPath(roundedRect: doos.insetBy(dx: 2, dy: 2), cornerRadius: 0.5)
            binnen.lineWidth = 0.5
            binnen.stroke()
            let midden = NSMutableParagraphStyle()
            midden.alignment = .center
            func regelTekst(_ s: String, _ font: UIFont, _ kern: CGFloat, y: CGFloat) {
                NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: Papier.stempel, .kern: kern, .paragraphStyle: midden])
                    .draw(in: CGRect(x: doos.minX, y: y, width: doos.width, height: font.lineHeight))
            }
            regelTekst("AFGEVINKT", Papier.barlow(5.5), 0.5, y: doos.minY + 4)
            regelTekst(Datumopmaak.kort(regel.datum, kalender: inhoud.kalender), Papier.barlow(8, .bold), 0.2, y: doos.minY + 10)
            regelTekst(regel.uitvoerder.label.uppercased(), Papier.barlow(5.5), 0.5, y: doos.minY + 20)
            cg.restoreGState()
        }

        // MARK: Hulpjes

        mutating func kop(_ tekst: String) {
            teken(tekst, font: Papier.schibsted(22, .bold), kleur: Papier.ink)
            y += 10
        }

        mutating func haarlijn() {
            Papier.haarlijn.setStroke()
            let pad = UIBezierPath()
            pad.move(to: CGPoint(x: marge, y: y))
            pad.addLine(to: CGPoint(x: pagina.width - marge, y: y))
            pad.lineWidth = 0.5
            pad.stroke()
        }

        func meet(_ tekst: String, font: UIFont, breedte: CGFloat) -> CGFloat {
            let rect = NSAttributedString(string: tekst, attributes: [.font: font])
                .boundingRect(with: CGSize(width: breedte, height: .greatestFiniteMagnitude),
                              options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            return ceil(rect.height)
        }

        /// Tekent tekst op de huidige `y` en schuift `y` door.
        mutating func teken(_ tekst: String, font: UIFont, kleur: UIColor, x: CGFloat = marge, breedte: CGFloat? = nil) {
            let b = breedte ?? self.breedte
            let hoogte = meet(tekst, font: font, breedte: b)
            let stijl = NSMutableParagraphStyle()
            stijl.lineBreakMode = .byWordWrapping
            NSAttributedString(string: tekst, attributes: [.font: font, .foregroundColor: kleur, .paragraphStyle: stijl])
                .draw(in: CGRect(x: x, y: y, width: b, height: hoogte))
            y += hoogte
        }
    }
}

/// Het pdf-bestand als deelbaar item. Het renderen gebeurt pas bij het delen.
struct DossierBestand: Transferable {
    let inhoud: DossierInhoud

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .pdf) { bestand in
            let veilig = bestand.inhoud.woningnaam
                .components(separatedBy: CharacterSet(charactersIn: "/\\:?*\"<>|")).joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            let map = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: map, withIntermediateDirectories: true)
            let url = map.appendingPathComponent("Onderhoudsdossier \(veilig.isEmpty ? "woning" : veilig).pdf")
            try DossierPDF.maak(bestand.inhoud).write(to: url)
            return SentTransferredFile(url)
        }
    }
}

# Ontwerp: het onderhoudsboekje

Het hele ontwerp is een onderhoudsboekje: een rustig blad met rijen en haarlijnen, en één stempel per afgevinkte klus. Het mag nergens aanvoelen als een generieke app.

## Principes

- **Geen kaarten.** Een scherm is één blad (`surfaceRaised`, hoek 18) met rijen, gescheiden door een haarlijn. Geen schaduwen, geen gradiënten.
- **Drie hoeken, elk met een eigen rol:** 2 pt voor de Stempel (en de Waarschuwing en het vinkvakje), 10 pt voor knoppen en invoervelden, 18 pt voor het blad.
- **Geen emoji, geen illustraties, geen clipart.** SF Symbols alleen waar het om functie gaat (vinkje, wissen, kiezen), regular weight. De tabbalk is tekst zonder pictogrammen.
- **Beeld is van de gebruiker** (foto van een typeplaatje, kitnaad, bon), nooit stockbeeld.
- **Geen accent in één woord van een kop, geen label in hoofdletters boven een kop.** Hoofdletters bestaan alleen in de Stempel.
- **Status heeft altijd een woord.** Kleur komt erbij en draagt nooit alleen.
- **Beweging beantwoordt een handeling.** Niets beweegt uit zichzelf bij het laden van een scherm.

## Kleurtokens

Color Sets in `Huisonderhoud/Resources/Assets.xcassets`, met licht en donker. Swift-namen in `Ontwerp/Kleur.swift`.

| naam | licht | donker | gebruik |
|---|---|---|---|
| `surface` | #ECEEE8 | #121A16 | achtergrond van het scherm |
| `surfaceRaised` | #F7F8F4 | #1B2620 | het blad, invoervelden |
| `ink` | #14261D | #E8EDE6 | titels en tekst |
| `inkMuted` | #56605A | #A3AEA5 | secundaire tekst |
| `line` | #C9CEC4 | #2E3B33 | haarlijn tussen rijen (decoratief) |
| `lineStrong` | #7C847B | #6B7A70 | rand van invoervelden en secundaire knoppen |
| `brand` | #1F5C43 | #7FC7A2 | knoppen, links, focus; alleen voor wat je aanraakt |
| `onBrand` | #F7F8F4 | #0F2A1E | tekst op brand |
| `mennie` | #BC3620 | #FF8A70 | Te laat en Let op |
| `oker` | #8A5F00 | #E8B94A | statustekst Deze maand |
| `stempelblauw` | #2A4B8D | #8FB0F0 | uitsluitend de Stempel |

### Contrast

Tekstkleuren halen minimaal 4,5:1 op `surface` en `surfaceRaised` in beide thema's; randen minimaal 3:1. Dit controleert `KleurcontrastTests` op de echte asset catalog. Gemeten (licht op `surface` / donker op `surface`):

| token | licht | donker |
|---|---|---|
| `ink` | 13,56 | 14,93 |
| `inkMuted` | 5,58 | 7,73 |
| `brand` | 6,73 | 8,94 |
| `mennie` | 4,87 | 7,70 |
| `oker` | 4,83 | 9,68 |
| `stempelblauw` | 7,21 | 8,13 |
| `onBrand` op `brand` | 7,37 | 7,73 |
| `lineStrong` (rand) | 3,30 | 3,92 |

Op `surfaceRaised` liggen de waarden in hetzelfde bereik. De laagste tekstwaarde is `oker` (licht, op `surface`: 4,83), de laagste randwaarde `lineStrong` (licht, op `surface`: 3,30). Er zijn geen afwijkingen.

## Typografie

Schibsted Grotesk voor alle tekst, Barlow Condensed uitsluitend in de Stempel (beide SIL Open Font License). De bestanden staan in `Huisonderhoud/Resources/Fonts/` en zijn geregistreerd in `UIAppFonts`; er wordt niets runtime opgehaald. Ontbreekt een bestand, dan valt de app terug op het systeemlettertype. Alle stijlen schalen mee met Dynamic Type.

| stijl | font | grootte/regelhoogte | gewicht | gebruik |
|---|---|---|---|---|
| `titelGroot` | Schibsted | 34/38, -0,01 em | 700 | één per scherm |
| `kop` | Schibsted | 22/28 | 700 | groepskop (Te laat, Deze maand) |
| `taak` | Schibsted | 17/22 | 600 | titel van een rij, labels |
| `body` | Schibsted | 17/24 | 400 | tekst en invoer |
| `uitleg` | Schibsted | 17/26 | 400 | uitleg, regels maximaal ongeveer 60 tekens |
| `klein` | Schibsted | 13/18 | 500 | statusregel en meta |
| `stempelTekst` | Barlow Condensed | 13/14, 0,08 em, hoofdletters | 600 | woorden in de Stempel |
| `stempelDatum` | Barlow Condensed | 24/24, 0,02 em | 700 | datum in de Stempel |

PostScript-namen (gecontroleerd aan de bestanden): `SchibstedGrotesk-Regular`, `-Medium`, `-SemiBold`, `-Bold`, `BarlowCondensed-SemiBold`, `-Bold`.

## Ruimte

4, 8, 12, 16, 24, 40 pt (`Ontwerp/Ruimte.swift`). Rij: 12 pt boven en onder, 16 pt opzij, minimaal 64 pt hoog. Knop: 48 pt hoog. Schermrand: 16 pt. Focus (toetsenbord en Switch Control): 2 pt ring in `brand`.

## Componenten

- **Stempel** (`datum`, `door`): rechthoek met rand van 2 pt in `stempelblauw` en een binnenrand van 1 pt op 3 pt afstand, hoek 2 pt, 2,5 graden tegen de klok in. Drie regels: AFGEVINKT, de datum ("3 okt 2026"), ZELF of VAKMAN. Toegankelijke naam: "Afgevinkt op 3 okt 2026, door zelf". Bij het afvinken landt hij één keer (schaal 1,15 naar 1 in 140 ms, haptic `.light`) en beweegt daarna nooit meer. Bij Verminder beweging verschijnt hij zonder animatie.
- **TaakRij**: links de titel (`taak`) met eronder de statusregel (`klein`; te laat in mennie semibold, deze maand in oker semibold, later en gedaan in `inkMuted`); rechts "Zelf, 15 min", of bij een afgevinkte klus de Stempel. Geen chevron. De hele rij is aanraakbaar. Bij toegankelijkheidsmaten staat de rechterkant onder de tekst.
- **Knop**: `primair` (brand-vlak), `secundair` (rand 1,5 pt `lineStrong`), `tekst` (brand-tekst). 48 pt hoog, hoek 10, label 17 semibold. Labels zijn werkwoorden: "Afvinken", "Notitie toevoegen", nooit "OK" of "Doorgaan". Maximaal één primaire knop per scherm.
- **Waarschuwing** (kop standaard "Let op"): omlijnd blok, rand 1,5 pt mennie, hoek 2, kop in mennie, tekst in ink. Alleen voor veiligheid. Geen pictogram.
- **Invoerveld, Keuzemenu, Keuzerij, Zoekveld**: `surfaceRaised`, rand `lineStrong` 1,5 pt (focus: `brand` 2 pt), hoek 10. De gekozen optie in een Keuzerij heeft een vinkje en een dikkere rand; kleur draagt het nooit alleen.
- **Vinkje** (`VinkjeStijl` voor `Toggle`): een vakje van 26 pt met hoek 2 pt. Het is een merkteken op het blad, geen knop; daarom krijgt het de hoek van de Stempel en niet die van een knop.
- **Tabbalk**: vier tekst-tabs (Nu, Schema, Boekje, Huis). De actieve tab is `brand` en bold, de rest `inkMuted`.

## Toegankelijkheid

Een eis, geen extraatje: Dynamic Type tot en met de grootste toegankelijkheidsmaten, VoiceOver-labels en -waarden (rijen lezen als één regel, de Stempel met zijn volledige naam, vinkjes met "aan" of "uit"), minimaal 44 x 44 pt aanraakvlakken, ondersteuning voor Verminder beweging, licht en donker thema. Haarlijnen en andere decoratie staan verborgen voor VoiceOver.

## Toon van de tekst

Schrijf zoals een buurman die het weet: kort, concreet, "je". Zinnen met een hoofdletter vooraan. Geen uitroeptekens. Een handeling heeft één naam door de hele flow: de knop heet Afvinken, de stempel zegt Afgevinkt. Fouten en lege schermen leggen uit wat er is en wat je kunt doen. De teksten van taken komen uit de dataset; herschrijf ze niet.

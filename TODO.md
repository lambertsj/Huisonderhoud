# TODO

Wat Jeroen nog moet invullen of kiezen. Dit is geen backlog voor de app: de app zelf is klaar voor v1 volgens de opdracht.

## Voor de App Store

- [ ] **Team** instellen (`DEVELOPMENT_TEAM` in `project.yml`, nu leeg).
- [ ] **Bundle-id** bevestigen. Nu de placeholder `nl.basisapps.huisonderhoud` (en `.tests`).
- [x] **App-icoon**: een voorstel staat erin (de Stempel met vinkje, drie kleuren). Zie `AppStore/README.md`; vervang het als je iets anders wilt.
- [ ] **App Store-gegevens** (screenshots staan al in `AppStore/screenshots-6.9/`): naam, subtitel, beschrijving, trefwoorden, screenshots, leeftijdsclassificatie, supportlink.
- [ ] **Privacylabel** in App Store Connect: "Gegevens niet verzameld". Past bij `PrivacyInfo.xcprivacy` en `PRIVACY.md`.
- [ ] **Privacy-URL** (bijvoorbeeld de gerenderde `PRIVACY.md` op GitHub of basisapps.nl).
- [ ] **iPad**: de app is nu alleen voor iPhone (`TARGETED_DEVICE_FAMILY: "1"`). Zet op `"1,2"` als je iPad wilt en test de indelingen.

## Licentie

- [x] Alles is MIT: `LICENSE` geldt voor de code en de dataset. De lettertypen behouden hun eigen OFL-licentie (teksten in `Huisonderhoud/Resources/Fonts/`).

## Inhoud

- [x] Dataset goedgekeurd voor v1. De openstaande inhoudelijke voorstellen (taken die twee keer per jaar lijken) staan onderaan `docs/DATASET.md` voor een volgende versie.
- [ ] **De vijf BasisApps-afspraken** op het scherm Huis > Over zijn geschreven vanuit de punten in de opdracht (gratis, reclamevrij, geen trackers en geen account, gegevens op je toestel, open source). Controleer de formulering tegen de afspraken op basisapps.nl.

## Links

- [ ] **URL van de broncode.** In de app staat nu `https://github.com/lambertsj/Huisonderhoud` (de `origin` van deze repository) in `Schermen/Huis/OverGroep.swift`. Pas aan als de definitieve URL anders is.
- [ ] **Basis Certified-badge.** De app linkt alleen naar basisapps.nl; de badge is niet nagemaakt. Wil je hem als bundle-asset, voeg hem dan zelf toe.

## Technisch, om te weten

- **String Catalog.** `Localizable.xcstrings` (primaire taal `nl`) is gevuld met de letterlijke teksten uit de code. Teksten die via een `String`-parameter lopen (bijvoorbeeld `Schermkop(titel:)` of `Lijstrij`) worden niet door Xcode geëxtraheerd en staan er dus niet in; de app is alleen Nederlands en toont ze correct. Wil je vertalen, laat die parameters dan `LocalizedStringKey` accepteren. `tools/stringcatalog-bijwerken.py` vult de catalog aan na een build.
- **Importeren bij een nieuwe telefoon** kan nu alleen via Huis > Gegevens, dus pas na de onboarding. Een "Gegevens importeren"-knop op het eerste scherm zou herstellen eenvoudiger maken; dat is bewust niet gebouwd omdat het eerste scherm in de opdracht vastligt.
- **Datum van het snappen.** Bij een voorkeursmaand die niet de huidige is, krijgt een taak een vaste dag in die maand tussen de 1e en de 20e (stabiel per taak-id), zodat niet alle meldingen op de 1e vallen.
- **Late afvinking en voorkeursmaanden.** De volgende datum is `afvinkdatum + interval`, daarna gesnapt naar de eerstvolgende voorkeursmaand. Vink je een jaarlijkse taak met voorkeursmaand november pas in december 2026 af, dan wordt dat december 2027 en dus november 2028: bijna twee jaar na de vorige keer. Dat volgt de opdracht letterlijk. Wil je dat verzachten, dan is dat een keuze in `Planning.volgendeDatum`.

# Privacy

Huisonderhoud verzamelt niets en doet geen netwerkverzoeken.

- Alles wat je invult of afvinkt (woning, taken, apparaten, notities, foto's) staat alleen op je telefoon.
- Er is geen account, geen server, geen analyse, geen crash-reporting en geen advertentienetwerk.
- De app bevat geen netwerkcode en geen code van derden.
- Foto's kies je zelf uit je fotobibliotheek met de systeemkiezer. De app krijgt alleen de foto's die je kiest en vraagt geen toegang tot je hele bibliotheek of tot de camera.
- Herinneringen zijn lokale meldingen. Ze worden op je telefoon gepland; er gaat niets de deur uit.
- Het pdf-dossier en de export maak je op je telefoon. Waar je ze daarna naartoe deelt, bepaal jij.
- Links naar basisapps.nl en de broncode openen in je browser. Dat is jouw browser, niet de app.

Het privacy manifest (`Huisonderhoud/Resources/PrivacyInfo.xcprivacy`) meldt: geen tracking, geen verzamelde data. De enige required-reason API die de app gebruikt is `UserDefaults` (reden `CA92.1`), voor de schakelaar voor herinneringen.

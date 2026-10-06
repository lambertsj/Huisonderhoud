# App Store-materiaal

- `screenshots-6.9/`: zes screenshots van 1320 x 2868 pixels (iPhone 6,9 inch, zonder alfakanaal), met een korte kop in de stijl van de app. Dezelfde bestanden kun je voor de kleinere iPhone-formaten laten schalen door App Store Connect.
- Het app-icoon staat in `Huisonderhoud/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024 x 1024, geen alfakanaal, drie kleuren: `brand`, `surfaceRaised`, `stempelblauw`).

## Opnieuw maken

```sh
# Icoon
swiftc -O tools/maak-icoon.swift -o /tmp/maak-icoon
/tmp/maak-icoon Huisonderhoud/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png

# Screenshots: bouw voor de iPhone 17 Pro Max, start de app met `-screenshotdata` en maak
# opnames in AppStore/ruw/ (1-nu, 2-detail, 3-boekje, 4-schema, 5-huis, 6-onboarding):
#   -screenshotdata                              Nu
#   -screenshotdata -open-taak verwarming-cv-waterdruk   2-detail
#   -screenshotdata -tab boekje | -tab schema | -tab huis
#   -leeg                                        6-onboarding
# Zet eerst de statusbalk schoon:
#   xcrun simctl status_bar booted override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
swiftc -O tools/maak-screenshots.swift -o /tmp/maak-screenshots
/tmp/maak-screenshots AppStore/ruw AppStore/screenshots-6.9
```

De voorbeelddata (Huis aan de Dijk, een gevuld Boekje) zit alleen in DEBUG-builds (`Voorbeeld.screenshotContainer`) en komt niet in de app voor gebruikers.

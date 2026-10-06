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

## App Store Connect

`tools/asc-metadata.py` zet de teksten uit `metadata-nl.json`, de categorieën, de leeftijdsclassificatie, de inhoudsrechten en de screenshots in App Store Connect (zie het script voor het gebruik). `tools/asc.py` is de kleine API-helper. Een build maak je zo:

```sh
xcodebuild -project Huisonderhoud.xcodeproj -scheme Huisonderhoud -configuration Release -destination 'generic/platform=iOS' -archivePath H.xcarchive archive -allowProvisioningUpdates -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_<ID>.p8 -authenticationKeyID <ID> -authenticationKeyIssuerID <ISSUER>
xcodebuild -exportArchive -archivePath H.xcarchive -exportPath export -exportOptionsPlist AppStore/ExportOptions.plist <dezelfde authenticatie-opties>
xcrun altool --upload-app -f export/Huisonderhoud.ipa -t ios --apiKey <ID> --apiIssuer <ISSUER>
```

Sleutels staan nooit in de repository. Verhoog `CURRENT_PROJECT_VERSION` in `project.yml` voor elke nieuwe upload.

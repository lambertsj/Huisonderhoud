# Huisonderhoud

Weet altijd wat er aan je huis moet gebeuren, voordat het een probleem wordt.

Huisonderhoud is een gratis, open iOS-app voor eigenaar-bewoners, vooral eerste kopers. Je vinkt aan wat bij je huis hoort (cv-ketel, plat dak, houten kozijnen, enzovoort) en krijgt automatisch een onderhoudsschema op maat. Elke afgevinkte klus komt met datum, uitvoerder, notitie en foto in een logboek, het Boekje. Dat kun je bewaren als pdf-onderhoudsdossier, bijvoorbeeld voor een verkoop.

De app is onderdeel van [BasisApps](https://basisapps.nl): gratis, open Nederlandse apps.

## De afspraken

- **Echt gratis.** Geen abonnement, geen aankopen, geen betaalmuur, geen pro-functies. Het pdf-dossier is gratis.
- **Reclamevrij.** Geen advertenties, banners of pop-ups.
- **Geen trackers.** Geen analyse, geen crash-reporting, geen dataverkoop.
- **Geen account.** Geen login, geen backend, geen eigen server.
- **Je gegevens blijven op je telefoon.** De app doet geen enkel netwerkverzoek en gebruikt geen externe afhankelijkheden (geen Swift Packages, geen CocoaPods).
- **Open source.** De code staat openbaar op GitHub.

Geen upsell, geen tellers, geen streaks, geen confetti en geen uitnodigingen om te delen of te beoordelen. Zie [PRIVACY.md](PRIVACY.md).

## Bouwen

Je hebt Xcode 26 nodig en [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). Het Xcode-project staat ook in de repository, dus XcodeGen is alleen nodig als je `project.yml` wijzigt.

```sh
xcodegen generate            # alleen na een wijziging in project.yml
open Huisonderhoud.xcodeproj # bouwen en draaien in Xcode
./build.sh test              # bouwen en alle tests, met korte uitvoer
```

Een `DEBUG`-build kent twee opstartopties, handig voor screenshots en UI-tests:

| argument | effect |
|---|---|
| `-voorbeelddata` | start met een gevuld schema, alleen in het geheugen |
| `-leeg` | start met een lege opslag in het geheugen (onboarding) |
| `-tab boekje` | start op de tab Nu, Schema, Boekje of Huis |

Teamnaam, bundle-id, app-icoon en App Store-gegevens staan nog open: zie [TODO.md](TODO.md).

## Opbouw

| map | wat |
|---|---|
| `Huisonderhoud/App` | opstart en wortelscherm |
| `Huisonderhoud/Domein` | SwiftData-modellen, planning, status, eerste schema, voorstellen |
| `Huisonderhoud/Catalogus` | laden en valideren van `onderhoudstaken.json` |
| `Huisonderhoud/Meldingen` | meldingplanner (puur) en de dunne laag om `UserNotifications` |
| `Huisonderhoud/Dossier` | pdf-onderhoudsdossier |
| `Huisonderhoud/Opslag` | export en import (JSON), foto's verkleinen |
| `Huisonderhoud/Ontwerp` | kleur- en typografietokens en componenten |
| `Huisonderhoud/Schermen` | de schermen; ze blijven dun |
| `Huisonderhoud/Resources` | dataset, lettertypen, asset catalog, String Catalog, privacy manifest |
| `HuisonderhoudTests` | tests (Swift Testing) |
| `docs` | [dataset](docs/DATASET.md), [ontwerp](docs/ONTWERP.md) en het JSON Schema |

De catalogus (de onderhoudstaken) is read-only en zit in de app. Alles wat jij aanmaakt of afvinkt staat in SwiftData. Zo komt een correctie in de dataset bij iedereen aan via een app-update, zonder migratie van gebruikersdata.

## Bijdragen

- **Een taak toevoegen of corrigeren?** Lees [docs/DATASET.md](docs/DATASET.md). Wijzig `Huisonderhoud/Resources/onderhoudstaken.json`, draai `./build.sh test` en leg uit waarom. Intervallen zijn algemene richtlijnen; het voorschrift van de fabrikant of installateur gaat altijd voor.
- **Een fout of idee?** Open een issue.
- **Code?** Houd je aan de afspraken hierboven en aan [docs/ONTWERP.md](docs/ONTWERP.md). Nieuwe logica krijgt een test; views blijven dun. Voeg geen netwerkcode of externe afhankelijkheden toe.

## Licentie

Alles in deze repository valt onder de MIT-licentie, zie [LICENSE](LICENSE): de code en ook de dataset (`onderhoudstaken.json`). De lettertypen Schibsted Grotesk en Barlow Condensed vallen onder hun eigen SIL Open Font License (die is niet te vervangen door MIT); de licentieteksten staan in `Huisonderhoud/Resources/Fonts/`.

# De dataset: onderhoudstaken.json

`Huisonderhoud/Resources/onderhoudstaken.json` is de catalogus van onderhoudstaken. Hij zit als bundle-resource in de app, wordt bij het opstarten gelezen en is read-only. Een correctie komt bij iedereen aan via een app-update.

> Intervallen zijn algemene richtlijnen. Het voorschrift van de fabrikant of installateur gaat altijd voor.

## Schema

Het formele schema staat in [onderhoudstaken.schema.json](onderhoudstaken.schema.json). Een test valideert de dataset ertegen.

```json
{
  "meta": { "versie": "0.1-concept" },
  "taken": [ { ... } ]
}
```

`meta.versie` verandert bij elke inhoudelijke wijziging. Andere velden in `meta` (zoals `status`, `licentie` en `velden`) zijn toegestaan en worden door de app genegeerd.

| veld | type | betekenis |
|---|---|---|
| `id` | string | Stabiele id, kleine letters en koppeltekens. **Verander een id nooit** na een release: gebruikers verwijzen ernaar. |
| `titel` | string | Titel van de taak. |
| `categorie` | string | Een van: Veiligheid, Verwarming, Water, Dak en gevel, Ramen en deuren, Ventilatie, Vocht, Badkamer en keuken, Apparaten, Energie, Tuin, Seizoen. |
| `interval_maanden` | getal of `null` | Om de hoeveel maanden de taak terugkomt. `null` = komt niet vanzelf terug. |
| `maanden` | lijst van 1 tot 12 | Voorkeursmaanden (1 = januari). Mag leeg zijn. |
| `uitvoering` | string | `zelf`, `vakman` of `zelf_of_vakman`. |
| `duur_min` | getal of `null` | Ruwe duur in minuten. |
| `voorwaarde` | lijst van tags | Voor welke huizen de taak geldt. **Any-of**: één match is genoeg. Leeg = voor elk huis. |
| `uitleg` | string | Wat je doet, in gewone taal. Niet leeg. |
| `waarschuwing` | string, optioneel | Alleen voor veiligheid (gas, elektra, hoogte, vocht). Laat het veld weg als er geen is. |

### Tags

`gas`, `houtkachel`, `open_haard`, `cv_ketel`, `radiatoren`, `warmtepomp`, `boiler`, `buitenkraan`, `regenton`, `schuin_dak`, `plat_dak`, `houten_kozijnen`, `dakraam`, `rolluiken`, `mechanische_ventilatie`, `wtw`, `afzuigkap`, `kruipruimte`, `droger`, `zonnepanelen`, `airco`, `tuin`.

Een gebruiker kiest in de onboarding geen losse tags maar kenmerken die meerdere tags zetten (zie `Domein/Kenmerken.swift`). Een test controleert dat elke tag in de dataset via de onboarding bereikbaar is. Voeg je een nieuwe tag toe, voeg hem dan ook toe aan het schema, aan `Kenmerken.tagTitels` en aan een keuze in `Kenmerken.keuzes`.

## Hoe de app de dataset gebruikt

- **Volgende datum.** Bij afvinken: afvinkdatum plus `interval_maanden`. Heeft de taak `maanden`, dan wordt het resultaat gesnapt naar de eerstvolgende voorkeursmaand op of na die datum. Een taak met `interval_maanden: 12` en `maanden: [11]` blijft zo in november hangen.
- **Eerste schema.** Taken met voorkeursmaanden komen in hun eerstvolgende voorkeursmaand. Taken met een interval tot en met 3 maanden starten tussen 1 en 4 weken vanaf nu. De rest wordt gespreid over de komende 1 tot 3 maanden. **Zware taken** (interval van 12 maanden of meer én `vakman`) worden gevraagd: "Wanneer deed je dit voor het laatst?".
- **Een nieuwe versie** voegt nooit stilzwijgend taken toe. De gebruiker ziet "N nieuwe taken voor jouw huis" en kiest.
- **Een taak die uit de dataset verdwijnt** blijft bestaan als eigen taak, met de laatst bekende tekst, interval en voorkeursmaanden. Het Boekje blijft leesbaar door de snapshots in elke uitvoering.
- **Teksten corrigeren** werkt voor alle bestaande taken: de app toont altijd de tekst uit de huidige dataset.

## Een taak toevoegen of corrigeren

1. Voeg de taak toe of pas hem aan in `Huisonderhoud/Resources/onderhoudstaken.json`. Schrijf zoals een buurman die het weet: kort, concreet, "je". Geen uitroeptekens.
2. Verhoog `meta.versie`.
3. Draai `./build.sh test`. De tests controleren het schema, unieke ids, geldige waarden en dat elke tag bereikbaar is.
4. Leg in je pull request uit waarom, liefst met een bron (handleiding, brancheorganisatie, RVO).

Verzin geen taken en geen onderhoudsregels. Twijfel je over een interval, schrijf het dan hieronder op als voorstel in plaats van het stilzwijgend te wijzigen.

## Voorstellen en open punten

Dit zijn opmerkingen bij de startset; ze zijn bewust niet doorgevoerd in de code of in de dataset.

1. **Status van de dataset.** `meta.status` zegt dat de startset nog gecontroleerd moet worden voordat hij in de app gaat. Dat is nog niet gebeurd.
2. **Taken die twee keer per jaar bedoeld lijken.** Door het snappen naar voorkeursmaanden gedragen sommige taken zich als jaarlijks, ook als de maanden twee keer per jaar suggereren:
   - `dak-pannen-inspectie`: `interval_maanden: 12`, `maanden: [4, 10]`. Afgevinkt in april komt hij pas weer in april. Bedoeld je twee keer per jaar, gebruik dan `interval_maanden: 6`.
   - `tuin-bomen-snoeien`: `interval_maanden: 12`, `maanden: [2, 9]`. Zelfde patroon.
3. **Een kwartaaltaak met één voorkeursmaand.** `verwarming-cv-waterdruk` heeft `interval_maanden: 3` en `maanden: [10]`. Na afvinken springt hij naar de volgende oktober, dus hij is feitelijk jaarlijks. Als elk kwartaal bedoeld is, past `maanden: [1, 4, 7, 10]`; als jaarlijks bedoeld is, past `interval_maanden: 12`.
4. **Alleen-vakman taken.** Vijf taken tellen als zwaar: `verwarming-cv-onderhoud`, `verwarming-warmtepomp`, `verwarming-schoorsteen`, `water-boiler-ontkalken` en `ventilatie-box-onderhoud`. Staat er een taak bij die je niet wilt vragen, zet dan `uitvoering` op `zelf_of_vakman`.
5. **Meer voorwaarden voor stadsverwarming.** Een cv-ketel kan ook op stadsverwarming zijn aangesloten. De onboarding is hierin een vereenvoudiging; het profiel is bewerkbaar op het scherm Huis, per tag.

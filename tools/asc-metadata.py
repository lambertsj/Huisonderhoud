#!/usr/bin/env python3
"""Zet de App Store-gegevens uit AppStore/metadata-nl.json in App Store Connect.

Gebruik: ASC_KEY_ID=... ASC_ISSUER_ID=... python3 -I tools/asc-metadata.py
Idempotent: opnieuw draaien overschrijft met dezelfde waarden. Wat niet via de API kan
(de privacy-antwoorden "Gegevens niet verzameld") moet in de webinterface.
"""
import json, os, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import asc

hier = pathlib.Path(__file__).resolve().parent.parent
m = json.loads((hier / "AppStore/metadata-nl.json").read_text())
APP = os.environ.get("ASC_APP_ID", "6819667424")

app = asc.get(f"/v1/apps/{APP}")["data"]
versie = asc.get(f"/v1/apps/{APP}/appStoreVersions")["data"][0]
vid = versie["id"]
print("versie", versie["attributes"]["versionString"], versie["attributes"]["appStoreState"])

# Versie: copyright
asc.patch(f"/v1/appStoreVersions/{vid}", {"data": {"type": "appStoreVersions", "id": vid,
          "attributes": {"copyright": m["copyright"]}}})

# Lokalisatie van de versie
loc = asc.get(f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations")["data"][0]["id"]
asc.patch(f"/v1/appStoreVersionLocalizations/{loc}", {"data": {"type": "appStoreVersionLocalizations", "id": loc,
          "attributes": {"description": m["beschrijving"], "keywords": m["trefwoorden"],
                         "promotionalText": m["promotietekst"], "supportUrl": m["supportUrl"]}}})
print("beschrijving, trefwoorden, promotietekst en support-URL gezet")

# App-info: ondertitel, privacy-URL, categorieën
info = asc.get(f"/v1/apps/{APP}/appInfos")["data"][0]["id"]
il = asc.get(f"/v1/appInfos/{info}/appInfoLocalizations")["data"][0]["id"]
asc.patch(f"/v1/appInfoLocalizations/{il}", {"data": {"type": "appInfoLocalizations", "id": il,
          "attributes": {"subtitle": m["ondertitel"], "privacyPolicyUrl": m["privacyUrl"]}}})
asc.patch(f"/v1/appInfos/{info}", {"data": {"type": "appInfos", "id": info, "relationships": {
    "primaryCategory": {"data": {"type": "appCategories", "id": "LIFESTYLE"}},
    "secondaryCategory": {"data": {"type": "appCategories", "id": "PRODUCTIVITY"}}}}})
print("ondertitel, privacy-URL en categorieën (Lifestyle, Productiviteit) gezet")

# Leeftijdsclassificatie: nergens inhoud die relevant is
leeftijd = {"data": {"type": "ageRatingDeclarations", "id": info, "attributes": {
    "advertising": False, "gambling": False, "healthOrWellnessTopics": False, "lootBox": False,
    "messagingAndChat": False, "parentalControls": False, "ageAssurance": False,
    "unrestrictedWebAccess": False, "userGeneratedContent": False,
    "alcoholTobaccoOrDrugUseOrReferences": "NONE", "contests": "NONE", "gamblingSimulated": "NONE",
    "gunsOrOtherWeapons": "NONE", "medicalOrTreatmentInformation": "NONE", "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE", "sexualContentOrNudity": "NONE", "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE", "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE", "violenceRealisticProlongedGraphicOrSadistic": "NONE"}}}
asc.patch(f"/v1/ageRatingDeclarations/{info}", leeftijd)
print("leeftijdsclassificatie ingevuld (4+)")

# Inhoudsrechten
asc.patch(f"/v1/apps/{APP}", {"data": {"type": "apps", "id": APP,
          "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}})
print("inhoudsrechten: geen content van derden")

# Informatie voor de beoordelaar (contactgegevens vul je zelf in)
try:
    rd = asc.get(f"/v1/appStoreVersions/{vid}/appStoreReviewDetail")["data"]
except SystemExit:
    rd = None
if rd and rd["attributes"].get("notes") == m["beoordelingsnotities"]:
    pass  # staat er al; de contactgegevens vul je zelf in (naam, telefoon, e-mail)
else:
    # PATCH eist alle contactvelden; zonder contactgegevens maken we het record opnieuw aan.
    if rd:
        contact = {k: v for k, v in rd["attributes"].items() if k.startswith("contact") and v}
        if len(contact) == 4:
            asc.patch(f"/v1/appStoreReviewDetails/{rd['id']}", {"data": {"type": "appStoreReviewDetails", "id": rd["id"],
                      "attributes": {"notes": m["beoordelingsnotities"]}}})
            rd = "bijgewerkt"
        else:
            asc.delete(f"/v1/appStoreReviewDetails/{rd['id']}")
    if rd != "bijgewerkt":
        asc.post("/v1/appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails",
                 "attributes": {"demoAccountRequired": False, "notes": m["beoordelingsnotities"]},
                 "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}})
print("beoordelaarsnotities gezet")

# Screenshots (iPhone 6,9 inch (API-type APP_IPHONE_67), 1320 x 2868), in de volgorde van de bestandsnamen
import hashlib, urllib.request
if os.environ.get("ASC_SCREENSHOTS", "1") == "1":
    sets = asc.get(f"/v1/appStoreVersionLocalizations/{loc}/appScreenshotSets")["data"]
    bestaand = next((s for s in sets if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67"), None)
    if bestaand:  # opnieuw beginnen met een lege set
        for sh in asc.get(f"/v1/appScreenshotSets/{bestaand['id']}/appScreenshots")["data"]:
            asc.delete(f"/v1/appScreenshots/{sh['id']}")
        set_id = bestaand["id"]
    else:
        set_id = asc.post("/v1/appScreenshotSets", {"data": {"type": "appScreenshotSets",
                          "attributes": {"screenshotDisplayType": "APP_IPHONE_67"},
                          "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc}}}}})["data"]["id"]
    for pad in sorted((hier / "AppStore/screenshots-6.9").glob("*.png")):
        data = pad.read_bytes()
        s = asc.post("/v1/appScreenshots", {"data": {"type": "appScreenshots",
                     "attributes": {"fileName": pad.name, "fileSize": len(data)},
                     "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
        for op in s["attributes"]["uploadOperations"]:
            deel = data[op["offset"]:op["offset"] + op["length"]]
            req = urllib.request.Request(op["url"], data=deel, method=op["method"],
                                         headers={h["name"]: h["value"] for h in op["requestHeaders"]})
            urllib.request.urlopen(req).read()
        asc.patch(f"/v1/appScreenshots/{s['id']}", {"data": {"type": "appScreenshots", "id": s["id"],
                  "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
        print("screenshot geüpload:", pad.name)

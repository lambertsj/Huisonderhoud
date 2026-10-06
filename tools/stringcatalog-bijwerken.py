#!/usr/bin/env python3
"""Zet de teksten uit de code in Huisonderhoud/Resources/Localizable.xcstrings.

Xcode doet dit zelf als je het project in Xcode bouwt. Dit script doet hetzelfde vanaf de
opdrachtregel, uit de .stringsdata-bestanden die een build achterlaat. Bestaande
vertalingen en handmatige keuzes blijven staan; er wordt niets verwijderd.

Gebruik (na een build):  python3 tools/stringcatalog-bijwerken.py <map-met-stringsdata>
"""
import json
import pathlib
import sys

catalogus = pathlib.Path(__file__).resolve().parent.parent / "Huisonderhoud/Resources/Localizable.xcstrings"
bron = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
if bron is None or not bron.is_dir():
    sys.exit(__doc__)

data = json.loads(catalogus.read_text())
strings = data.setdefault("strings", {})
nieuw = 0
for pad in sorted(bron.rglob("*.stringsdata")):
    inhoud = json.loads(pad.read_text())
    for sleutel_info in inhoud.get("tables", {}).get("Localizable", []):
        sleutel = sleutel_info["key"]
        if not sleutel or sleutel in strings:
            continue
        strings[sleutel] = {
            "extractionState": "extracted_with_value",
            "localizations": {"nl": {"stringUnit": {"state": "translated", "value": sleutel_info.get("value", sleutel)}}},
        }
        nieuw += 1
data["strings"] = dict(sorted(strings.items()))
catalogus.write_text(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=False) + "\n")
print(f"{nieuw} nieuwe teksten, {len(strings)} in totaal")

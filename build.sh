#!/bin/sh
# Bouwt of test met korte uitvoer: alleen fouten, waarschuwingen en het eindresultaat.
# Gebruik: ./build.sh [build|test] [simulatornaam]
set -e
cd "$(dirname "$0")"
ACTIE="${1:-build}"
SIM="${2:-iPhone 17 Pro}"
xcodegen generate >/dev/null 2>&1 || true
xcodebuild -project Huisonderhoud.xcodeproj -scheme Huisonderhoud \
  -destination "platform=iOS Simulator,name=$SIM" "$ACTIE" 2>&1 \
  | grep -E "(error|warning): |Test run|✘|TEST (SUCCEEDED|FAILED)|BUILD (SUCCEEDED|FAILED)|Issue" \
  | grep -v -E "not stripping binary|Metadata extraction skipped|CoreData" | cut -c1-400

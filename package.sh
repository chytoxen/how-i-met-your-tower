#!/usr/bin/env bash
# Build the Windows exe and bundle it into a versioned, shareable zip.
# (For a real installer instead of a zip, compile installer/setup.iss with Inno Setup on Windows.)
set -euo pipefail

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VER="$(tr -d '[:space:]' < "$PROJ/VERSION")"

"$PROJ/build_windows.sh"

DIST="$PROJ/builds/dist"
rm -rf "$DIST"
mkdir -p "$DIST"
cp "$PROJ/builds/HowIMetYourTower.exe" "$DIST/"
cp "$PROJ/HOW-TO-PLAY.txt" "$DIST/" 2>/dev/null || true

ZIP="$PROJ/builds/HowIMetYourTower-v${VER}.zip"
rm -f "$ZIP"
( cd "$DIST" && zip -j "$ZIP" ./* >/dev/null )
echo "Packaged: $ZIP"
ls -la "$ZIP"

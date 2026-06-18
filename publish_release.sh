#!/usr/bin/env bash
# Cut a GitHub release for the CURRENT version and refresh the update manifest.
# Prereqs: `gh auth login` done once, repo already created with a remote.
# Usage:  ./publish_release.sh "What changed in this version"
#
# To ship an update: bump VERSION + CURRENT_VERSION in core/Updater.gd
# (+ MyAppVersion in installer/setup.iss), then run this.
set -euo pipefail

PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJ"
VER="$(tr -d '[:space:]' < VERSION)"
NOTES="${1:-Release v$VER}"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"

# Build + zip the Windows game.
./package.sh

# Refresh the manifest the in-game updater reads.
cat > version.json <<EOF
{
  "version": "$VER",
  "url": "https://github.com/$REPO/releases/latest",
  "notes": "$NOTES"
}
EOF

git add version.json VERSION core/Updater.gd installer/setup.iss
git commit -m "Release v$VER" || true
git push

gh release create "v$VER" "builds/HowIMetYourTower-v${VER}.zip" \
  --title "v$VER" --notes "$NOTES"

echo "Released v$VER for $REPO"
echo "Manifest: https://raw.githubusercontent.com/$REPO/main/version.json"

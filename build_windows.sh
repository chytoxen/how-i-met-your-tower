#!/usr/bin/env bash
# Re-export the single-file Windows build.
# Requires: Godot 4.7 headless binary + matching export templates installed.
# Override the engine path with: GODOT=/path/to/godot ./build_windows.sh
set -euo pipefail

GODOT="${GODOT:-/home/chytoxen/godot/godot}"
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$PROJ/builds"
"$GODOT" --headless --path "$PROJ" --export-release "Windows Desktop" "builds/HowIMetYourTower.exe"
echo "Built: $PROJ/builds/HowIMetYourTower.exe"

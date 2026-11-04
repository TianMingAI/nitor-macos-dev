#!/bin/bash
# Build, replace /Applications/__NAME__.app and relaunch it (local testing after every change).
set -euo pipefail
cd "$(dirname "$0")"
./build.sh
DEST="/Applications/__NAME__.app"
pkill -f "$DEST/Contents/MacOS/__NAME__" || true
sleep 0.5
rm -rf "$DEST"
ditto "build/__NAME__.app" "$DEST"
codesign --verify --deep --strict "$DEST"
open "$DEST"
echo "Installed and relaunched: $DEST ($(cat VERSION))"

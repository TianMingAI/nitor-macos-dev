#!/bin/bash
# Release: build → DMG (drag to Applications) → sign → notarize → staple → verify.
#   ./release.sh              full release (notarization takes a few minutes)
#   SKIP_NOTARIZE=1 ./release.sh   local test DMG only
# Upload to the GitHub release: dist/__NAME__-<ver>.dmg, dist/__NAME__.dmg and dist/appcast.xml (Sparkle feed).
# NOTES_FILE (default build/notes.md, "## 中文 … ## English …") becomes the update window's notes.
# NOTARY_PROFILE defaults to "notary" (xcrun notarytool store-credentials, stored on this Mac).
set -euo pipefail
cd "$(dirname "$0")"
NAME="__NAME__"
VOLUME="__NAME_ZH__"
VERSION=$(cat VERSION)
APP="build/$NAME.app"
DMG="dist/__NAME__-$VERSION.dmg"

RELEASE=1 ./build.sh
IDENTITY=$(security find-identity -v -p codesigning | grep -m1 "Developer ID Application" | sed -E 's/.*"(.*)"/\1/')
[ -n "$IDENTITY" ] || { echo "需要 Developer ID Application 证书"; exit 1; }

# dmgbuild writes the Finder layout without scripting Finder.
if [ ! -x build/.venv/bin/dmgbuild ]; then
  python3 -m venv build/.venv
  build/.venv/bin/pip install --quiet "dmgbuild==1.6.5"
fi
swift scripts/dmg-background.swift build/dmg-background.png build/dmg-background@2x.png "__DMG_HINT__"
tiffutil -cathidpicheck build/dmg-background.png build/dmg-background@2x.png -out build/dmg-background.tiff >/dev/null

mkdir -p dist
rm -f "$DMG"
build/.venv/bin/dmgbuild -s scripts/dmg-settings.py -D app="$APP" -D background=build/dmg-background.tiff "$VOLUME" "$DMG"
codesign --force --timestamp --sign "$IDENTITY" "$DMG"

if [ "${SKIP_NOTARIZE:-0}" != "1" ]; then
  xcrun notarytool submit "$DMG" --keychain-profile "${NOTARY_PROFILE:-notary}" --wait
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  spctl --assess --type open --context context:primary-signature -vv "$DMG"
  cp "$DMG" "dist/__NAME__.dmg"                 # fixed-name copy for "latest" download links

  # Sparkle appcast (sign after stapling: stapling changes the DMG's bytes).
  SPARKLE_BIN=.build/artifacts/sparkle/Sparkle/bin
  SIG=$("$SPARKLE_BIN/sign_update" "$DMG")     # sparkle:edSignature="…" length="…"
  BUILD=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$APP/Contents/Info.plist")
  NOTES_HTML=$(python3 - "${NOTES_FILE:-build/notes.md}" <<'PY'
import html, re, sys, pathlib
p = pathlib.Path(sys.argv[1])
text = p.read_text() if p.exists() else ""
zh = text.split("## English")[0].replace("## 中文", "").strip()
out = []
for line in zh.splitlines():
    line = html.escape(line.strip())
    line = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", line)
    if line.startswith("- "): out.append(f"<li>{line[2:]}</li>")
    elif line: out.append(f"<p>{line}</p>")
print("\n".join(out))
PY
)
  cat > dist/appcast.xml <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>__NAME_ZH__ __NAME__</title>
    <item>
      <title>__NAME_ZH__ $VERSION</title>
      <pubDate>$(LC_ALL=C date -R)</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <sparkle:fullReleaseNotesLink>https://github.com/__REPO__/releases/tag/v$VERSION</sparkle:fullReleaseNotesLink>
      <description><![CDATA[$NOTES_HTML]]></description>
      <enclosure url="https://github.com/__REPO__/releases/download/v$VERSION/__NAME__-$VERSION.dmg" $SIG type="application/octet-stream"/>
    </item>
  </channel>
</rss>
XML
  xmllint --noout dist/appcast.xml && echo "Appcast: dist/appcast.xml (upload it with the DMGs)"
fi
echo "DMG: $DMG"

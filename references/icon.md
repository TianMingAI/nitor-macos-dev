# Icon

## App icon: Icon Composer package compiled by actool

macOS 26 renders icons through Icon Composer (`.icon` packages: `icon.json` + SVG/PNG layers) with Liquid Glass; `actool` also emits a classic `AppIcon.icns` for older systems. No Xcode project needed.

The generator writes `Resources/AppIcon.icon`:
- `icon.json`: `"fill": {"automatic-gradient": "srgb:0.078,0.078,0.078,1"}` (near-black, Vercel), one group, neutral shadow 0.3, translucency off, `supported-platforms.squares: ["macOS"]`.
- `Assets/glyph.svg`: a Lucide icon (ISC) on a 1024 canvas, `transform="translate(176 176) scale(28)"` (the 24-unit grid becomes 672 px centred), white stroke, width 1.9.

build.sh compiles it:

```bash
xcrun actool "$PWD/Resources/AppIcon.icon" --compile "$PWD/$APP/Contents/Resources" --platform macosx \
  --minimum-deployment-target 13.0 --app-icon AppIcon --target-device mac \
  --output-partial-info-plist "$PWD/build/icon-partial.plist"
```

and Info.plist has `CFBundleIconFile = AppIcon`, `CFBundleIconName = AppIcon`. Use absolute paths; on "currentDirectoryPath is unexpectedly nil" kill `ibtoold` and retry (pitfalls).

## Choosing the glyph

- The glyph names the job, not the brand: notebook-pen for notes, scissors for clipping, zap for quick capture. Search lucide.dev; combine at most two glyphs (main + small badge) as separate layers.
- One strong silhouette that reads at 16 px. Avoid thin details and text.
- Colour: default black fill + white glyph. A single brand colour fill is fine if the app has a reason; never purple by default.
- To iterate, edit the SVG/JSON and rebuild; or open the `.icon` in Icon Composer (Xcode 26) for glass and depth tweaks.

## Verify

```bash
# after build: extract the compiled icon and look at it
sips -s format png build/X.app/Contents/Resources/AppIcon.icns --out /tmp/icon.png
sips -Z 32 /tmp/icon.png --out /tmp/icon-32.png
```

View both. Check the glyph is optically centred (Lucide glyphs with heavy top or left parts may need a small translate) and that it still reads at 32 px. Then check the Dock and Finder after `install-local.sh` (Finder caches icons: `touch` the app or `killall Dock` if stale).

Rendering Lucide SVGs to PNG: ImageMagick can't parse Lucide's compact path syntax; render with `NSImage(contentsOf:)` in a tiny Swift script or `qlmanage -t -s 1024`.

## Menu bar glyph

SF Symbol by name (`--symbol`), or a template PDF/PNG at 18×18 pt (@2x 36 px) with `isTemplate = true`. It must be monochrome so it inverts with the menu bar. Consider a state variant (filled when active).

## README/DMG art

- `docs/assets/icon.png` (256–512 px) for the README header.
- DMG background is drawn by `scripts/dmg-background.swift` (title + hint line + arrow, 1x/2x TIFF, flipped context so text isn't mirrored).
- Social preview 1280×640 (`docs/assets/social-preview.png`): icon + name + tagline on black.

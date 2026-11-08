# Nitor customization validation — 2026-11-08

Validated scope: branding, optional owner assets, Codex metadata and the retained macOS design direction. This report replaces upstream runtime claims that did not apply to the modified template.

## Passed

- `python3 -m unittest discover -s tests -v`: 6 tests passed. Covers menu-bar/window scaffolds, substitution, offline icon fallback, invalid name/nonempty directory guards, independent optional QR assets, exact brand JSON copying and preservation of upstream license attribution.
- The test suite compiled and executed the production `Brand.swift` with Swift: Nitor defaults, missing configuration fallback, empty optional links, valid GitHub/mailto links and rejection of invalid link schemes/query-bearing email input passed.
- Codex `skill-creator/scripts/quick_validate.py`: valid frontmatter and skill name.
- `agents/openai.yaml`: explicit `$nitor-macos-dev` invocation and automatic discovery enabled.
- Local Markdown links and JSON parse checks passed; generated shell scripts passed `bash -n`; `git diff --check` passed.
- Active template/instruction scan found no old author website, social URL, profile dependency or promotional identity. Original MIT attribution remains in LICENSE, NOTICE.md, generated legal notices and marked historical research.
- Credential scan found no private key blocks or GitHub token values.

## Visual check

Compiled the production AboutSettings/QRCard and Brand.swift in an isolated AppKit/SwiftUI harness, with only app metadata and update actions stubbed. Rendered and visually reviewed light and dark snapshots (520 × 276): Nitor branding and GitHub displayed, absent website/email/public account/QR cards hidden, no leftover promotional space. The harness uses an explicit color scheme and background and attaches the hosting view to an offscreen window. The icon is a placeholder because no complete app bundle was built. This validates the changed About layout, not the full app lifecycle or updater.

## Environment limits

A generated window app was submitted to `swift build -c release`. After retrying outside the filesystem sandbox, public dependencies resolved to KeyboardShortcuts 2.0.2 and Sparkle 2.10.1. The build stopped in KeyboardShortcuts' `#Preview` declarations because Command Line Tools lacks `PreviewsMacros.SwiftUIView`. Only Command Line Tools is selected; full Xcode/actool is unavailable. This is an environment/dependency baseline limitation, not a successful app build.

No complete .app bundle, Developer ID signing, Apple notarization, DMG, installed-app smoke test or Sparkle update round-trip was performed. Those require a complete Xcode environment and the relevant distribution credentials when an actual app is developed.

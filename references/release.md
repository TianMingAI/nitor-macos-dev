# Release: Sign, Notarize, DMG

For .pkg installers, native-messaging helpers and browser-extension bundles, read qiaomu-dev-skill `references/macos-pkg.md` instead; this file covers standalone `.app` + DMG.

## One-time machine setup (record where things live, never the secrets)

- **Developer ID Application** certificate in the login keychain (`security find-identity -v -p codesigning`).
- Notary credentials: `xcrun notarytool store-credentials notary --apple-id <id> --team-id <team>` with an app-specific password, stored in the keychain profile **`notary`**. If missing, ask the user to run that command themselves; never type their password.
- Python 3 (release.sh creates `build/.venv` with dmgbuild 1.6.5 on first run).
- Sparkle key in the keychain (auto-update.md).

## Versioning

- `VERSION` holds the marketing version (semver). Bump it in the release PR; tag `vX.Y.Z` after merge.
- `CFBundleVersion` is a timestamp, always increasing; Sparkle compares it.
- Never change the bundle id after the first public release (it's the identity for prefs, TCC, Sparkle).

## `./release.sh`

1. `RELEASE=1 ./build.sh` → universal (arm64 + x86_64), hardened runtime, secure timestamp, nested Sparkle signed inside-out (never `--deep`).
2. Draw the DMG background (`scripts/dmg-background.swift`, 1x + 2x → `tiffutil -cathidpicheck`).
3. `dmgbuild` (auto-installed into `build/.venv`, pinned 1.6.5) with `scripts/dmg-settings.py`: app + Applications alias, icon positions, window size. **Don't use `hide_extensions`**: it writes FinderInfo that breaks `codesign --strict` on the app.
4. Sign the DMG, notarize it (`notarytool submit --keychain-profile notary --wait`; notarizing the DMG covers the app inside), staple, `stapler validate`, and `spctl --assess --type open --context context:primary-signature -vv` must say "Notarized Developer ID".
5. Copy to a fixed name `dist/<Name>.dmg` for "latest" links.
6. `sign_update` the **stapled** DMG → `dist/appcast.xml`, with release notes from `NOTES_FILE` (default `build/notes.md`, "## 中文 … ## English …"; the Chinese half goes into the update window).

`SKIP_NOTARIZE=1 ./release.sh` builds the DMG without Apple round-trips, for checking the layout first. Run the fast local checks before slow notarization.

## Look at the DMG

Mount it and screenshot the Finder window (`hdiutil attach`, `open`), or render the background TIFF. Check: text not mirrored, arrow between the app and Applications, names readable in light/dark, window not cut off. Then eject.

## Publish on GitHub

```bash
gh release create vX.Y.Z dist/<Name>-X.Y.Z.dmg dist/<Name>.dmg dist/appcast.xml \
  --repo <owner>/<repo> --title "<中文名> X.Y.Z" --notes-file /tmp/notes.md
```

Notes: Chinese first, what's new for users (not commit logs), then English summary. README download badge points at `releases/latest/download/<Name>.dmg`.

Verify from the public side: download the DMG URL, compare `shasum`, `spctl` it, mount it, launch the app from it once. For private repos release assets need auth; public download only works once the repo is public.

## Notarization failures

- `notarytool log <id> --keychain-profile notary` shows the reason.
- "not signed with a valid Developer ID" → a nested binary was missed; sign inside-out.
- "The signature does not include a secure timestamp" → build with `RELEASE=1`.
- "hardened runtime not enabled" → `--options runtime` on every Mach-O.
- Stapler error 65 right after acceptance → wait a minute and retry.

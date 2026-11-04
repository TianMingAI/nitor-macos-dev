# Auto-Update (Sparkle 2)

## Wiring (already in the template)

- SwiftPM dependency `Sparkle` ≥ 2.10.1; the framework is copied into `Contents/Frameworks` and signed inside-out by build.sh.
- Info.plist: `SUFeedURL = https://github.com/<owner>/<repo>/releases/latest/download/appcast.xml`, `SUPublicEDKey` from `Resources/sparkle-public-key.txt`, `SUEnableAutomaticChecks = true` (Sparkle's default interval is one day).
- `Updater.swift`: `SPUStandardUpdaterController(startingUpdater: true, …, userDriverDelegate: self)`, `checkForUpdates()` for the menu and About button, `automaticallyChecks` bound to the About checkbox.
- **Gentle reminders** for accessory apps: set `supportsGentleScheduledUpdateReminders` to true, and in `standardUserDriverShouldHandleShowingScheduledUpdate` return false when not in immediate focus, then show your own toast ("有新版本 1.2.0 · 更新") that calls `checkForUpdates()`. Without this a background menu bar app pops a window over whatever the user is doing.

## Keys

`scripts/sparkle-key.sh` runs `generate_keys -p` (from `.build/artifacts/sparkle/Sparkle/bin`). If no key exists it creates one in the login keychain (item "ed25519", shared by all your Sparkle apps). Only the public key is written to the repo.

- Back up the private key once: `generate_keys -x ~/Desktop/sparkle-key.txt`, store it in a password manager, delete the file. Losing it means existing installs can never update again.
- Never put the private key in CI secrets unless the user decides to; releases are built locally.

## Appcast

`release.sh` writes `dist/appcast.xml` with one item: `sparkle:version` = `CFBundleVersion` (monotonic timestamp), `sparkle:shortVersionString` = VERSION, `sparkle:minimumSystemVersion`, `enclosure url=…/releases/download/vX.Y.Z/<Name>-X.Y.Z.dmg` with the `sparkle:edSignature` and `length` from `sign_update`. Release notes: a short Chinese HTML list in `<description>`.

**Sign the DMG after stapling** — stapling changes the bytes and invalidates an earlier signature.

Upload `appcast.xml` as a release asset of every release; `releases/latest/download/appcast.xml` then always serves the newest one. Don't mark pre-releases "latest" unless you want everyone on them.

## Verify after publishing

```bash
curl -sL https://github.com/<o>/<r>/releases/latest/download/appcast.xml | grep -o 'shortVersionString>[^<]*'
curl -sL -o /tmp/u.dmg <enclosure url> && shasum -a 256 /tmp/u.dmg   # matches dist/
.build/artifacts/sparkle/Sparkle/bin/sign_update --verify /tmp/u.dmg "<edSignature>"
```

Then test an actual update: install the previous version, click 检查更新, confirm it downloads, replaces and relaunches. If the app was moved out of /Applications or is translocated (run from the DMG), Sparkle can't replace it: the DMG hint and first-run check should tell users to drag it to Applications.

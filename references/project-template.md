# Project Template

`scripts/new_app.py` copies `assets/template/` and substitutes `__NAME__`, `__NAME_ZH__`, `__BUNDLE_ID__`, `__REPO__`, `__TAGLINE__`, `__SYMBOL__`, `__DMG_HINT__`, `__MENUBAR__`. It also writes the icon, About QR codes, VERSION (0.1.0), .gitignore, MIT LICENSE, THIRD_PARTY_NOTICES.md and runs `git init -b main`.

## Layout

```
Package.swift                SwiftPM executable; KeyboardShortcuts + Sparkle
Sources/<Name>/main.swift    AppInfo, FloatingPanel, AppDelegate (menus, panel/main window, settings), --snapshot, --selftest
Sources/<Name>/Theme.swift   Vercel tokens, Geist registration, PanelView (menubar) and MainView (window) starters
Sources/<Name>/SettingsView.swift  SettingsTabs, GeneralSettings, AboutSettings, Links
Sources/<Name>/Updater.swift Sparkle wrapper with gentle reminders
Sources/<Name>/Toast.swift   non-activating toast with actions ("已保存  撤销")
Resources/AppIcon.icon       Icon Composer package (icon.json + SVG layers)
Resources/About/             wechat-qr.jpg, reward-qr.png (owned by 向阳乔木, not MIT)
Resources/<Name>.entitlements  hardened-runtime entitlements (apple-events by default)
Resources/sparkle-public-key.txt  written by scripts/sparkle-key.sh
build.sh                     swift build → .app bundle → Info.plist → actool icon → sign
release.sh                   RELEASE=1 universal build → notarize → staple → DMG → notarize DMG → appcast
install-local.sh             quit running copy, replace /Applications/<Name>.app, relaunch
scripts/dmg-background.swift draws the 1x/2x DMG background (flipped context)
scripts/dmg-settings.py      dmgbuild layout (pinned dmgbuild 1.6.5 in a venv)
scripts/sparkle-key.sh       resolves Sparkle, reads or creates the EdDSA key, writes the public key
```

## Shapes

- `--kind menubar`: `LSUIElement` true, status item, global hotkey toggles a non-activating `FloatingPanel`, settings shown once on first launch, reopen-from-Finder shows settings, launch at login on by default.
- `--kind window`: Dock app, main window with frame autosave, closing the last window keeps the app running and the Dock icon reopens it, ⌘0 shows the main window, no hotkey section in settings, launch at login off by default.

Switching later: flip `AppInfo.menuBar` and the `LSUIElement` value in build.sh.

## build.sh contract

- `RELEASE=1` → `swift build -c release --arch arm64 --arch x86_64`; otherwise native debug-fast build.
- Copies `Resources/{Fonts,Icons,Sounds,About}` when present. New resource folders must be added here, or they silently go missing (the logo bug).
- Info.plist gets version from `VERSION`, build number from a timestamp (`YYYYMMDDHHMM`, monotonic — Sparkle compares `CFBundleVersion`), `SUFeedURL` and `SUPublicEDKey`, localized display names (`LSHasLocalizedDisplayName`, `CFBundleLocalizations`, `en.lproj` / `zh-Hans.lproj` InfoPlist.strings). The bundle file name must equal `CFBundleName`.
- Icon compile self-heals the stale `ibtoold` helper (see pitfalls) and prints actool's log on failure.
- Signs Sparkle's nested XPC services, Autoupdate, Updater.app, the framework, then the app, all with `--options runtime`. Picks the first "Developer ID Application" identity, then "Apple Development", then ad-hoc (permissions will reset every build). Secure timestamp only when `RELEASE=1`.

## Extending

- New view → add a case to `snapshot()` so it can be reviewed.
- New logic → add `check(...)` lines to `selftest()`; keep it deterministic and offline.
- New dependency → add to Package.swift, THIRD_PARTY_NOTICES.md and `licenses/` if anything is bundled.
- New bundled fonts/sounds → `Resources/Fonts` / `Resources/Sounds` plus their license.

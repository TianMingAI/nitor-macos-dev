# Pitfalls Catalog

Symptom → cause → fix. Each one happened while building Jot or this template.

## Keyboard, focus, windows

| Symptom | Cause | Fix |
|---|---|---|
| ⌘V / ⌘C / ⌘A do nothing in a text field | Accessory app has no Edit menu | Install an invisible `NSApp.mainMenu` with Edit items |
| ⌘, doesn't open settings right after the hotkey panel appears (works after clicking the field) | Non-activating panel skips key equivalents | Panel `sendEvent` routes ⌘ chords to `performKeyEquivalent` → main menu |
| ⌘Q quits the whole app from the panel | Default menu behaviour | Swallow ⌘Q in the panel's `performKeyEquivalent` |
| Settings opens behind other windows or can't be typed into | Accessory activation policy | `.regular` while settings is open, back to `.accessory` on close |
| Shortcut recorder starts recording on open; keys fall through to the panel; × doesn't clear | Auto first responder + panel still key | `makeFirstResponder(nil)`, close the panel before showing settings |
| Two handlers fire after changing a shortcut | Old handler still registered | `KeyboardShortcuts.removeHandler(for:)` before re-adding |
| Can't drag the borderless window by its bar | SwiftUI controls swallow mouseDown | Drag-area NSView behind the bar calling `performDrag` |
| Settings title shows "未保存" | Window title not set per tab | `SettingsTabs` sets "App · Tab" on selection |
| Double-clicking the app in Finder "does nothing" | Menu bar app has no window | `applicationShouldHandleReopen` shows settings |

## Text and IME

| Symptom | Cause | Fix |
|---|---|---|
| Placeholder stays visible while typing pinyin | SwiftUI prompt ignores marked text | Custom NSTextView placeholder that hides when `hasMarkedText()` or text non-empty |
| Pinyin search misses (`yi'ji`) | IME composing text has `'` separators | Strip separators; match full pinyin and initials (`CFStringTransform` to Latin, strip diacritics) |
| Italic/bold regex breaks next to CJK | `\b` is ASCII-only around CJK | Explicit ASCII-only boundaries in the pattern |
| HTML → Markdown has mojibake | Decoding HTML via `Data` with the wrong encoding | `XMLDocument(xmlString:options:.documentTidyHTML)` from the String |
| "© 2,026" | `Text("\(intValue)")` localizes integers | `Text("\(String(intValue))")` or `verbatim:` |
| SF Symbol renders as Chinese text ("格式") | Some symbols are localized glyphs (`textformat`) | Use a text label ("Aa") or another symbol |

## SwiftUI lists and state

| Symptom | Cause | Fix |
|---|---|---|
| Search results show stale rows | `LazyVStack` reuse with rapidly changing data | Plain `VStack` + stable ids + `.id(query)` |
| Crash "index out of range" deleting a row | `ForEach($array)` binding to a removed index | Bind by id (`binding(for: id)`), defer removal to the next runloop |
| Window doesn't resize per settings tab | Hosting controller sizing | `sizingOptions = [.preferredContentSize]`, fixed width per tab |

## Files, clipboard, permissions

| Symptom | Cause | Fix |
|---|---|---|
| "未能拷贝 … 的许可" saving an image copied from WeChat | macOS 14+ App Data protection on another app's container | Prefer pasteboard image data over container file URLs; skip and report unreadable items |
| Permission prompts every build; Accessibility toggle "on" but not working | Ad-hoc signature changes each build | Sign every build with the same Developer ID |
| Logos/fonts missing in the built app | Resource folder not copied by build.sh | Add it to the copy loop; snapshot to confirm |
| Self-test pollutes the user's recent items | Shared persistence | Disable recents during self-test; filter temp paths |
| Password manager entries end up in history | Clipboard watcher ignores markers | Skip `org.nspasteboard.TransientType` / `ConcealedType` |

## Build, icon, packaging

| Symptom | Cause | Fix |
|---|---|---|
| `actool`: "IBCurrentDirectoryPath – currentDirectoryPath is unexpectedly nil" (build.sh exits silently after "Build complete") | The shared `ibtoold` helper's cwd was deleted (project folder removed and recreated) | Absolute paths, log to `build/actool.log`, on failure `pkill -x ibtoold` and retry (template does this) |
| `codesign --strict` fails on the stapled app inside the DMG | dmgbuild `hide_extensions` writes FinderInfo | Don't use `hide_extensions` |
| DMG background text mirrored | Drawing into an unflipped CGContext | `NSGraphicsContext(cgContext:flipped: true)` |
| ImageMagick can't render Lucide SVG | Compact path syntax | Render with NSImage / qlmanage |
| Notarization: missing secure timestamp | Debug build signed with `--timestamp=none` | `RELEASE=1` build |
| Sparkle update fails signature check | DMG signed with sign_update before stapling | Staple first, then `sign_update` |
| App shows English name in Chinese Finder | Missing localized display name | `LSHasLocalizedDisplayName`, `CFBundleLocalizations`, `zh-Hans.lproj/InfoPlist.strings`; bundle filename = `CFBundleName` |
| `sparkle-key.sh` fails on a fresh checkout | SwiftPM artifact cache race | Resolve with one retry (template does) |

## Shell (zsh on macOS)

- No `timeout` command on macOS; use `perl -e 'alarm N; exec @ARGV'` or background + kill.
- Never name a zsh variable `path` (it's tied to `$PATH`).
- `sed -i ''` on macOS (BSD sed), not `sed -i`.
- Folder names with spaces (`Nutstore Files`): always quote.

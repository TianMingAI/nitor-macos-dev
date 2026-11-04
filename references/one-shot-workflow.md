# One-Shot Workflow

Goal: from one sentence ("做一个记账的菜单栏小工具") to an installed, notarized, auto-updating app plus a GitHub repo, without the user babysitting each step.

## 0. Read the sentence

Extract, don't interrogate:

| Decide | Default when unstated |
|---|---|
| Pain point and the single core action | Infer from the sentence; write the tagline (≤ 20 汉字, says what it does *for you*) |
| Shape | `menubar` when the job is quick and frequent (capture, toggle, glance); `window` when the user works inside it for minutes (editor, library, dashboard) |
| Names | Chinese `乔木<词>`; English one short word; bundle id `ai.qiaomu.<slug>`; repo `joeseesun/qiaomu-<slug>` |
| Global hotkey | menubar: ⌥Space, but check it doesn't clash with something the user runs; recordable in settings |
| Min macOS | 13 (SMAppService, Settings APIs). Raise it only for a real API need |
| Storage | UserDefaults for prefs; files the user owns (Markdown/JSON in a folder they pick) for content |

Ask at most one question, and only if a wrong guess means rebuilding (for example menubar vs window when it's truly ambiguous).

## 1. Scaffold

Run `scripts/new_app.py` (see SKILL.md). Then `./scripts/sparkle-key.sh && ./build.sh && build/X.app/Contents/MacOS/X --selftest`. If it fails, fix the template in this skill too, not only the project.

## 2. Core feature

- Model and logic in plain Swift types with no UI. Every behaviour you can phrase as input → output gets a `check(...)` in `selftest()`.
- Keep side effects (file writes, network) behind a tiny type you can point at a temp dir in the self-test, and make the self-test never touch real user data (disable history/recents during it).
- Persist the user's content atomically (`Data.write(options: .atomic)` or append with a file handle) and never lose input on failure: show the error and keep the text.

## 3. UI

Follow ui-polish.md. Snapshot each surface in light and dark:
`build/X.app/Contents/MacOS/X --snapshot /tmp/x.png [--dark] [--settings general|about|main]`. Extend the `snapshot` switch for new views. Look at every PNG, iterate until it would pass a design review. For aesthetic choices with real alternatives, render three restrained directions side by side and pick one; don't stack effects.

## 4. Settings, About, onboarding

settings-about.md. Every pref has a sensible default; settings is for changing, not for setting up.

## 5. Icon

icon.md. Pick a Lucide glyph that names the job; compile; look at it at 1024 and in the Dock.

## 6. Permissions

permissions.md. Only request what a feature needs, at the moment it needs it, after an in-app explanation.

## 7. Dogfood

`./install-local.sh` after each build the user should try. Tell them what changed and what to try.

## 8. GitHub (private first)

github.md. Create the repo **private**. Write the README as a product page with real screenshots. Then ask: "要公开吗？" Only after yes: make it public, set the social preview, About and topics.

## 9. Release

release.md + auto-update.md. `./release.sh` does universal build → sign → notarize → staple → DMG → sign_update → appcast. Upload the DMG and `appcast.xml` to the GitHub Release (`gh release create vX.Y.Z dist/*.dmg dist/appcast.xml`). Verify from the public URL.

## Handoff (final message, Chinese)

1. What it does and how to open it (hotkey, menu bar icon, Dock).
2. What was verified, and how (selftest count, snapshots viewed, Gatekeeper output, appcast check).
3. Defaults chosen on the user's behalf (names, hotkey, shape), so they can veto.
4. What is *not* done or not verified (for example "仓库仍是私有", "未在 Intel 实机测试").
5. One suggested next step.

---
name: nitor-macos-dev
description: >-
  为 Nitor 开发和改进原生 macOS 应用（SwiftUI、AppKit、SwiftPM），包括菜单栏工具、普通窗口、设置与关于、图标、快捷键、系统权限、Sparkle 自动更新和签名公证 DMG。使用本 Skill 自带的黑白克制设计规范指导 Mac 界面。用于“做一个 Mac 软件”“开发 macOS app”及相关修复和分发；不用于网站、Electron/Tauri、iOS、浏览器插件或一般 Swift 问答。
---

# Nitor macOS Dev

Turn one sentence into a shipped, notarized, auto-updating Mac app that looks designed. Maintained for Nitor / TianMingAI. Upstream attribution is in NOTICE.md.

## Router

- New app → run the generator, then the [One-Shot Workflow](references/one-shot-workflow.md). Do not hand-write the skeleton.
- Existing app → read only the reference for the task (table below) and keep the project's conventions.
- For macOS work using this skill, read [UI Polish](references/ui-polish.md) and use its native black/white design system as the primary visual direction, including small UI changes. Do not substitute website-oriented frontend-design styling. Preserve existing app conventions unless redesign is requested; a newer explicit user direction wins. This exception is scoped to this skill, not global preferences.
- Branding comes from `assets/brand.json`; see [Branding](references/branding.md). Never invent contact links or reuse another author's promotional assets.
- Reply in Chinese; code, commands and identifiers stay English.
- Ask only what changes the build: the app's job in one line, Chinese + English name, menu bar vs window (infer when obvious). Everything else gets a good default and is listed in the handoff.

## Generate

Resolve paths from this installed skill directory before running the generator, even when the shell starts in the app repository. Do not assume `scripts/new_app.py` is in the current directory.

```bash
python3 scripts/new_app.py --dir ~/Code/nitor-<slug> --name <AsciiName> --zh <中文名> \
  --bundle-id ai.nitor.<slug> --repo TianMingAI/nitor-<slug> \
  --kind menubar|window --tagline "<一句话价值>" --lucide <icon> --symbol <sf-symbol>
cd ~/Code/nitor-<slug> && ./scripts/sparkle-key.sh && ./build.sh && build/<Name>.app/Contents/MacOS/<Name> --selftest
```

Build and self-test the generated project; initial selftest only checks its name, so add meaningful checks for the requested behavior. Full icon compilation needs Xcode 26+ actool. Signing falls back without Developer ID; report that limitation. It has a main menu (⌘, ⌘W ⌘Q and Edit keys), settings tabs plus About, Sparkle, launch at login, `--snapshot` / `--selftest`, `release.sh` (universal binary → notarize → staple → DMG → appcast) and `install-local.sh`. Details: [Project Template](references/project-template.md).

## One-Shot Phases (apply only within the requested scope)

1. **Intent**: pain point, the one core action, success in 10 seconds. Gate: one-line tagline.
2. **Scaffold**: the generator above. Gate: build + selftest pass.
3. **Core feature**: put logic in pure functions and grow `selftest()` with every feature. Gate: selftest passes.
4. **UI**: [UI Polish](references/ui-polish.md). Gate: snapshots in light and dark of every surface, looked at, not assumed.
5. **Settings + About + onboarding**: [Settings & About](references/settings-about.md). Gate: snapshot of each tab.
6. **Icon**: [Icon](references/icon.md). Gate: the icon is rendered and viewed at 1024 and 32 px.
7. **Permissions**: [Permissions](references/permissions.md). Gate: first-run path shows *why* before macOS asks.
8. **Install and dogfood**: `./install-local.sh` replaces /Applications and relaunches. Run only when local installation/replacement is authorized; otherwise provide the built app for testing.
9. **GitHub**: [GitHub](references/github.md). The repo is **private by default**; ask before making it public. README is a product page.
10. **Release**: [Release](references/release.md) + [Auto-Update](references/auto-update.md). Gate: Gatekeeper says "Notarized Developer ID", appcast version and EdDSA signature verified, a download from the release URL opens.

Before handing over, walk the [Details Checklist](references/details-checklist.md). When something breaks, check the [Pitfalls](references/pitfalls.md) first.

## Non-Negotiables

- **Look before you claim.** Render every user-visible surface with `--snapshot` (and the DMG window and icon), open the PNG, fix what looks wrong. Signature checks are not visual checks.
- **Design taste**: Vercel black/white, Geist, one accent at most, never purple, no muddy grey. Generous spacing, explicit close buttons, keyboard first. No vertical side-stripe accents (`border-left` bars); use a tint, weight or a small dot. Identify other apps by their logo (simple-icons, Lucide fallback), not by text.
- **Ordinary users first**: generic defaults that work with zero setup. Never tailor defaults to the developer's own folders. Save the user's content verbatim; never silently reformat it.
- **Prefer Developer ID on every build**, including dev builds, so macOS permission grants survive rebuilds. If absent, local development can use the script fallback; report it and do not claim distributable/notarized output. Hardened runtime. Sign nested code inside-out, never `--deep`.
- **Secrets never enter the repo or this skill**: the Sparkle private key stays in the login keychain, notarization uses the `notary` keychain profile, and only the public key is committed.
- **Git**: feature branch → PR → merge; never push to `main`. Publish, make public, or release only when the user asked. Existing authorization for that action persists across phases; do not ask again. A development request alone does not authorize publishing.
- Only update this installed skill or persistent preferences when the user explicitly requests it. Report useful lessons without silently saving them.

## Reference Map

| Task | Read |
|---|---|
| Phases, gates, handoff format | [one-shot-workflow](references/one-shot-workflow.md) |
| Generated files, scripts, how to extend | [project-template](references/project-template.md) |
| Menu bar, panels, focus, hotkeys, windows | [app-architecture](references/app-architecture.md) |
| Visual design, snapshots, motion, copy | [ui-polish](references/ui-polish.md) |
| Settings window, About, onboarding | [settings-about](references/settings-about.md) |
| App icon, menu bar glyph, DMG art | [icon](references/icon.md) |
| TCC, Accessibility, Apple Events, files from other apps | [permissions](references/permissions.md) |
| Sparkle, appcast, gentle reminders | [auto-update](references/auto-update.md) |
| Signing, notarization, DMG, versioning | [release](references/release.md) |
| Repo, README, About/topics, PRs, Releases | [github](references/github.md) |
| Known bugs and their fixes | [pitfalls](references/pitfalls.md) |
| The things users don't think to ask for | [details-checklist](references/details-checklist.md) |

Maintained by Nitor · https://github.com/TianMingAI · Upstream license: [NOTICE.md](NOTICE.md).

# Creation Handoff · qiaomu-macos-dev 1.0.0

## Result

- Skill: `qiaomu-macos-dev` 1.0.0 (Governed: public repo, release gates, secrets boundary)
- Job: one-sentence, one-shot development of a polished native macOS app, from scaffold to notarized DMG, auto-update and GitHub release
- Source: the full development of 乔木闪记 / Jot 1.0 → 1.5.0 (github.com/joeseesun/qiaomu-jot)

## Reference skills studied

- `charleswiltgen/axiom:axiom-macos` — learned: on-demand platform references. Applied: `references/` split by task with a routing table.
- `dimillian/skills:macos-menubar-tuist-app` — learned: a scaffold beats prose for app structure. Applied: `scripts/new_app.py`, but on SwiftPM without Tuist.
- `petekp/agent-skills:macos-app-design` — learned: native patterns first. Applied: AppKit shell + SwiftUI content, native preference toolbar; narrowed taste to one concrete system.
- `openclaw/openclaw:release-openclaw-mac` — learned: release as a scripted runbook with verification. Applied: `release.sh` + verification commands in `release.md` / `auto-update.md`.

Deliberate rejections: Xcode-project flows, `--deep` signing, sandbox-by-default, generic design advice. See `prior-art-research.md`.

## Evidence

| Claim | Label | Evidence |
|---|---|---|
| Generator produces a building, signed, self-testing app (menubar and window) | validated advantage | Built Pebble (menubar) and Ledger (window) on 2026-11-04: Developer ID signature, `--selftest` ALL PASS, `LSUIElement` true/false |
| UI surfaces render correctly | validated advantage | Snapshots of panel (light/dark), About, main window, settings viewed; About year bug ("2,026") found and fixed this way |
| `release.sh` produces a DMG | validated advantage | `SKIP_NOTARIZE=1 ./release.sh` → `dist/Pebble-0.1.0.dmg` |
| Full notarization + Sparkle flow works | validated (in source project) | Jot 1.4.0 / 1.5.0: Gatekeeper "Notarized Developer ID", appcast and EdDSA verified; not re-notarized for the demo apps |
| Trigger boundaries | validated | `reports/trigger-eval.json` 20/20 |
| Generator guards and substitution | validated | `tests/test_new_app.py` 4 tests |
| "One sentence → shipped app" end to end by a fresh agent | hypothesis | missing evidence: no fresh-session run yet |
| Better than the studied skills | hypothesis | no fair comparison run |

## Next iteration

- Run a fresh session with only "做一个 X 的 Mac 小工具" and record where it needed help.
- Add a hero-image generator script for READMEs.
- Fold lessons from each new app into `references/pitfalls.md` and bump the version.

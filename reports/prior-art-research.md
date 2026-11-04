# Prior-Art Research · qiaomu-macos-dev

Date: 2026-11-04. Runner: `research_prior_art.py` (skills.sh + SkillsMP), raw results in `prior-art-candidates.json`.

Queries: "macos app development swiftui", "notarize dmg sparkle", "menu bar app", "macos release signing". 150 candidate families after deduplication by repository + skill path. Metrics are kept separate: skills.sh installs = adoption; SkillsMP stars belong to the source repository; neither is a quality rating.

## Shortlist

| Candidate | Signal | Why shortlisted |
|---|---|---|
| `charleswiltgen/axiom:axiom-macos` | 1.4K skills.sh installs | Most-adopted macOS platform knowledge skill |
| `dimillian/skills:macos-menubar-tuist-app` | 693 installs | Closest in shape: menu bar app scaffold |
| `petekp/agent-skills:macos-app-design` | 411 installs | Design guidance for Mac apps |
| `openclaw/openclaw:release-openclaw-mac` | 62 installs | Real-world signing/notarization/release runbook |

Mirrors such as `petekp/claude-code-setup:macos-app-design` (38) and `openclaw-mac-release` (35) were collapsed into their families; metrics were not summed.

## Keep / Adapt / Reject / Invent

- **Keep**: platform-knowledge references loaded on demand (axiom); scripted, repeatable release steps with explicit verification commands (openclaw); HIG-aligned native patterns over custom chrome (petekp).
- **Adapt**: menu bar scaffold (dimillian) → rebuilt on plain SwiftPM + a `build.sh` bundler instead of Tuist, so there's no extra tool and the agent controls Info.plist, signing and icon compilation directly. Design guidance → narrowed to one concrete visual system (Vercel black/white + Geist) with tokens in code, because generic "follow the HIG" advice produced the UI the user rejected.
- **Reject**: Xcode-project-centric flows (agents can't drive Xcode's GUI reliably); `--deep` signing advice found in older material; Mac App Store sandbox as a default (blocks Accessibility/Apple Events that utility apps need).
- **Invent** (from shipping 乔木闪记 / Jot): a generator that produces a signed, self-testing app on the first build; `--snapshot` offscreen rendering as a mandatory visual gate; non-activating panel ⌘-key routing; About page with bundled QR cards; Sparkle gentle reminders for accessory apps; Icon Composer icon from Lucide via `actool` without Xcode; self-healing `ibtoold` retry; GitHub private-by-default with an explicit "go public?" question; a pitfalls catalog and a details checklist from real bugs.

## Missing evidence

- No side-by-side output comparison with the shortlisted skills was run; any "better than" claim is a hypothesis.
- Candidate code was read, not executed.
- No user ratings available on either catalog.

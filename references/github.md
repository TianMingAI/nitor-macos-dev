# GitHub: Repo, README, Releases

## Repo lifecycle

1. **Create private.** `gh repo create joeseesun/qiaomu-<slug> --private --source . --remote origin --description "<中文一句话> · <English one-liner>"`. Code, README and first release can all live there while private.
2. Work on branches: `git switch -c feat/<thing>` → commit → `git push -u origin HEAD` → `gh pr create` → review the diff → `gh pr merge --squash` (or merge commit for release PRs). **Never push to `main`.** The very first commit may go to `main` only when the repo is new and empty; after that, PRs.
3. **Ask before going public**: "仓库现在是私有的，README 和安装包都准备好了。要公开吗？" Only on a clear yes: `gh repo edit --visibility public --accept-visibility-change-consequences`.
4. After public: About description (bilingual), homepage (release page or website), topics, social preview, and re-check that README images and the download badge load for a logged-out visitor.

Topics: `macos`, `macos-app`, `menubar-app` / `swiftui`, `swift`, plus 2–4 domain words (`obsidian`, `markdown`, `productivity`). `gh repo edit --add-topic macos,swiftui,...`.

Social preview: `docs/assets/social-preview.png` 1280×640. GitHub's API can't set it; ask the user to upload it in Settings › Social preview, or upload it through the browser if they ask you to.

## README as a product page (Chinese first, English section after)

Structure that worked for Jot:

1. **Centered header**: icon (96 px) → `# 中文名 · English` → language switch → one bilingual sentence of value → badges (Download latest DMG, macOS 13+, Apple notarized, License; all in `#111` black) → hero image (820 px).
2. **已验证** line: concrete evidence (self-test count, notarized, universal binary). No claims you didn't check.
3. **这是什么**: the pain point as a small story ("记笔记最难的不是写，而是打开笔记…"), then how the app removes it. A table of the 2–3 core actions with their shortcuts.
4. **核心能力**: 5–8 bullets, each "what you can do → why it matters", not internal features.
5. **Output example** (what it writes/creates), as a code block or screenshot.
6. **快速开始**: download → drag to Applications → first launch permissions → first action, 4 steps max.
7. **产品巡游**: 3–5 real screenshots (panel light/dark, settings, about), each with a one-line caption.
8. **使用方式 / FAQ**: the questions real users will ask (does it need X? where is data stored? how to change the shortcut?).
9. **限制、隐私与边界**: what it does not do, what data stays local, which permissions and why.
10. **项目结构 + 从源码构建** for developers: `./build.sh`, `--selftest`, release notes.
11. **致谢**: libraries and icons with licenses (match THIRD_PARTY_NOTICES.md).
12. **关于向阳乔木**: one-paragraph bio, links (qiaomu.ai · 博客 · 乔木推荐 · X · GitHub), the two QR codes in a table (`docs/assets/wechat-qr.jpg`, `reward-qr.png`), "MIT © year 向阳乔木".
13. `# English`: a condensed translation: what it is, install, privacy & limits.

Writing rules: lead with the user's problem and outcome, short sentences, numbers over adjectives, no "强大的/革命性". Every image has alt text. Keep images in `docs/assets/`, PNG, ≤ 1 MB each.

### Making the images

- Screenshots: the app's own `--snapshot` renders (crisp, consistent) for panels and settings; real screenshots (`screencapture -l <windowid>` or `-R x,y,w,h`) when context matters (menu bar, other apps).
- Hero: compose a real screenshot on a clean background with one caption line, rendered by a small Swift/HTML script so it can be regenerated each release. Show the app *doing the job* (e.g. selection in Safari → saved note), not just a window.
- Re-shoot images when the UI changes; stale screenshots are a trust bug.

## Repo hygiene

- `.gitignore`: `.build/ .swiftpm/ build/ dist/ .DS_Store xcuserdata/`. Never commit DMGs; they go to Releases.
- LICENSE (MIT, 向阳乔木), THIRD_PARTY_NOTICES.md, `licenses/` for bundled fonts/icons/sounds.
- Issue templates are optional; at least make 反馈问题 in About open `issues/new`.
- Secret scan before every push: `git grep -nE "BEGIN (EC|RSA|OPENSSH) PRIVATE|ghp_|sk-[A-Za-z0-9]{20}"` must be empty. Never commit the Sparkle private key, notary credentials, or `.env`.
- Don't put the user's email or local paths in public files.

## Releases

See release.md for building. Release title "中文名 X.Y.Z", notes Chinese first, user-facing. Assets: versioned DMG, fixed-name DMG, appcast.xml. Verify the download URL and appcast after publishing (auto-update.md).

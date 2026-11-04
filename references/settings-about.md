# Settings, About, Onboarding

## Settings window

- `NSTabViewController` with `tabStyle = .toolbar` in an `NSWindow` with `toolbarStyle = .preference`: the native System Settings look, icons + labels across the top.
- Window title follows the tab: "乔木闪记 · 通用". Without this macOS may show "未保存" or the raw window name.
- `makeFirstResponder(nil)` on open and tab switch, so no field or shortcut recorder grabs the first key.
- Each tab: SwiftUI `Form { … }.formStyle(.grouped)` at a fixed width (520) and a height that fits its content (no big empty area); `NSHostingController.sizingOptions = [.preferredContentSize]` so the window resizes per tab.
- Typical tabs: 通用 (hotkey, launch at login, sound), the app's own domain tabs (保存 / 场景 / 记录 …), 关于. Keep it to ≤ 5.
- Every setting applies immediately; no Save button. Show a live preview when a setting changes output format (Jot shows the rendered note entry).
- Pickers over free text: time formats, locations, templates as dropdowns with examples; folder choice via `NSOpenPanel` plus typeahead search.
- Onboarding checklist at the top of 通用 until done (hotkey tried, permission granted, destination chosen); each row has a "去设置" button and a checkmark when complete.

## About tab (template `AboutSettings`)

Top to bottom:
1. App icon 64 pt, Chinese name, "English version" in monospace, tagline.
2. Four buttons: 检查更新 (Sparkle), 反馈问题 (GitHub new issue), 使用说明 (README), 源代码 (repo).
3. "自动检查更新" checkbox bound to Sparkle's `automaticallyChecksForUpdates`.
4. Two QR cards, bundled so they work offline: 关注公众号 (`About/wechat-qr.jpg`, "微信搜索「向阳乔木推荐看」") and 请我喝杯咖啡 (`About/reward-qr.png`). Sources: `~/.agents/skills/qiaomu-profile/assets/`. Resize the reward QR to ≤ 520 px.
5. Links: qiaomu.ai · 博客 · 乔木推荐 · X · GitHub.
6. Privacy line ("数据只保存在本机。" — only if true; otherwise say exactly what leaves the Mac).
7. "© <year> 向阳乔木 · MIT 许可 · 第三方许可见 THIRD_PARTY_NOTICES.md" with the year as `String(...)`.

The app menu and status menu "关于 X" open this tab instead of the bare `orderFrontStandardAboutPanel`.

## Onboarding

- Menu bar app: open settings once on first launch, with the checklist visible. Window app: an empty state in the main window that teaches the core action.
- Explain each permission before triggering the system prompt (permissions.md).
- A toast on the first successful action teaches the hotkey ("下次按 ⌥Space 直接打开").

# UI Polish

The user rejected three rounds of "fine" UI on Jot ("灰蒙蒙的", "依然十分丑陋") before landing on Vercel black/white. Start there.

## Visual language

- **Palette** (`Theme`): background #FFFFFF / #0A0A0A, bar #FAFAFA / #111111, border #EAEAEA / #262626, text #0A0A0A / #EDEDED, muted #666 / #A1A1A1. Primary button = solid text colour with inverse label. At most one accent, used for state (success, warning), never decoration. **No purple. No grey-on-grey low contrast.**
- **Type**: Geist (SIL OFL, bundle it in `Resources/Fonts` with its license) for Latin, system PingFang for CJK. Sizes: 22 title, 15 header, 13 body/control, 12 secondary, 11 caption. Weights regular/medium/semibold only.
- **Shape**: 12 pt continuous corner radius for panels, 6–7 for buttons and fields; 1 px hairline borders; soft system shadow only on floating windows.
- **Spacing**: 20 pt panel padding, 8 pt grid. Bottom bar 52 pt tall with hints on the left ("Esc 关闭") and the primary action on the right.
- **No side-stripe accents** (vertical `border-left` bars) for active rows, quotes or callouts. Use a background tint, weight change or a small dot.
- **Icons**: SF Symbols at matching weight; logos of other apps via simple-icons SVGs (Lucide fallback) rendered as template images. Never label a source app with plain text when a logo exists. Don't use an SF Symbol whose glyph renders as localized text (`textformat` showed "格式"); use a text label like "Aa".

## Interaction

- Keyboard first: every action has a shortcut shown in the UI or tooltip; ⌘↩ = primary; Esc = close/back (Esc in a search field returns to the previous view rather than closing the window).
- Placeholder disappears the instant typing starts, including during IME composition (custom NSTextView placeholder, not SwiftUI's prompt).
- Feedback for every action within 100 ms: toast "已保存 · 撤销" (non-activating, auto-dismiss, pauses on hover), sound optional (default a pleasant system sound such as "Glass").
- Empty states say what to do next, with one button.
- Destructive actions: undo over confirmation dialogs.
- Drag and drop: show a clear drop highlight; accept files, images, file promises (`NSFilePromiseReceiver`, for Photos/Mail), and URLs.
- Lists that change quickly: `VStack` in a `ScrollView` with stable ids (LazyVStack showed stale rows); give the list `.id(query)` to reset on new searches.
- Motion: 150–250 ms ease-out for appear/disappear; no bouncing; respect Reduce Motion.

## Copy

Chinese UI, short and active: "保存到 今日日记" not "点击此处可以保存". Name things by what the user gets. Errors say what happened and what to do ("没有权限读取这个文件，已跳过；可在 系统设置 › 隐私 中允许").

## Verify with snapshots (mandatory)

```bash
build/X.app/Contents/MacOS/X --snapshot /tmp/panel.png
build/X.app/Contents/MacOS/X --snapshot /tmp/panel-dark.png --dark
build/X.app/Contents/MacOS/X --snapshot /tmp/about.png --settings about
```

Open each PNG and review against: alignment on the 8 pt grid, contrast in both modes, truncation of long Chinese/English strings, number formatting (`Text("\(2026)")` renders "2,026": wrap ints in `String(...)`), empty and full states, and no leftover template text. Crop and zoom (`magick in.png -crop …`) to check small text. Real windows (title bars, menus) need a screenshot of the running app, not just a snapshot.

When there are genuine design alternatives, render three restrained options with the real content, compare side by side, then commit to one.

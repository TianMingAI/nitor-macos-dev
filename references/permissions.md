# Permissions (TCC) and Other Apps' Data

## Rules

- Ask only when a feature needs it, right when the user triggers it, after one sentence in your own UI saying why.
- Always handle "denied": explain in a toast/row, offer "打开系统设置" (deep link), and keep working with reduced features.
- **TCC grants are bound to the code signature.** Ad-hoc signatures change every build, so permissions silently reset and prompts repeat. Sign every build, even debug, with the same Developer ID (build.sh does).
- During development the user may need to remove stale entries: `tccutil reset Accessibility ai.qiaomu.x` (tell them; don't run resets on their behalf without asking).

## Common permissions

| Need | API | Plist / entitlement | Deep link |
|---|---|---|---|
| Read the selection in other apps, simulate ⌘C | AX (`AXIsProcessTrustedWithOptions`), CGEvent | none (not sandboxed) | `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility` |
| Ask Safari/Chrome for the current URL/title | Apple Events (`NSAppleScript`) | `NSAppleEventsUsageDescription` + `com.apple.security.automation.apple-events` | `…?Privacy_Automation` |
| Capture the screen | ScreenCaptureKit | `NSScreenCaptureUsageDescription` (macOS 15 re-prompts monthly) | `…?Privacy_ScreenCapture` |
| Mic / camera | AVFoundation | `NSMicrophoneUsageDescription` / `NSCameraUsageDescription` | `…?Privacy_Microphone` |
| Files in Desktop/Documents/Downloads | just access | the system prompts per folder; prefer user-picked folders | `…?Privacy_FilesAndFolders` |
| Global hotkeys | Carbon `RegisterEventHotKey` via KeyboardShortcuts | none | — |
| Local network | Bonjour | `NSLocalNetworkUsageDescription` | — |

Write usage descriptions in Chinese that say the benefit ("用于读取你在其他应用中选中的文字").

## Grabbing the selection safely

Try AX `kAXSelectedTextAttribute` first. If an app doesn't expose it, fall back to: save the pasteboard → synthesize ⌘C → wait for `changeCount` to change (≤ 300 ms) → read → restore the original pasteboard. Ignore pasteboards marked `org.nspasteboard.TransientType` / `ConcealedType` (password managers).

## Files and images from sandboxed apps

Sandboxed apps (WeChat, Mail, Photos) put file URLs on the pasteboard that point into their private containers. Since macOS 14 the "App Data" protection blocks reading those ("未能拷贝 … 的许可"). Prefer the pasteboard's own image/data representations (`NSImage(pasteboard:)`, `public.png`, `public.tiff`) over the file URL when the URL is inside `~/Library/Containers/` or `Group Containers`. For drags from Photos/Mail use `NSFilePromiseReceiver`. Skip unreadable items and report how many were skipped instead of failing the whole save.

## Sandbox?

Developer ID apps outside the Mac App Store usually stay unsandboxed: Accessibility, Apple Events to arbitrary apps and free file access are much harder in the sandbox. If targeting the App Store, plan sandboxing from day one (security-scoped bookmarks, temporary exceptions) and expect features to be cut.

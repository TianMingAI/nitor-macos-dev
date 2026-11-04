# App Architecture (AppKit shell, SwiftUI content)

AppKit owns windows, menus, focus and activation; SwiftUI draws content inside `NSHostingView`. Pure SwiftUI `MenuBarExtra` / `Settings` scenes look simpler but fail on the details below (focus, ⌘ keys, non-activating panels), so the template does not use them.

## Menu bar apps

- `LSUIElement` = true in Info.plist and `setActivationPolicy(.accessory)`: no Dock icon, no app menu bar.
- **Status item menu**: set `menu.delegate` and rebuild it in `menuNeedsUpdate` so titles, checkmarks and recent items are always current. Show the hotkey on the item with `NSMenuItem.setShortcut(for:)` (KeyboardShortcuts).
- Menu bar glyph: SF Symbol or a template image (`isTemplate = true`, 18 pt, monochrome), never the colour app icon.
- **Non-activating floating panel** (the capture window): `NSPanel` with `[.borderless, .nonactivatingPanel]`, `canBecomeKey = true`, `level = .floating`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `hidesOnDeactivate = false`. The user's frontmost app keeps focus, so "paste back" and source detection still work.
- **⌘ keys in a non-activating panel**: AppKit skips the menu key-equivalent pass for it, so ⌘V/⌘, /⌘W do nothing. Override `sendEvent` to call `performKeyEquivalent` for every ⌘ chord, and in `performKeyEquivalent` fall through to `NSApp.mainMenu`. Swallow ⌘Q in the panel (users hit it expecting to close the panel, not quit).
- **Invisible main menu**: install an `NSApp.mainMenu` even for an accessory app. It gives Edit (undo/cut/copy/paste/select all), ⌘, settings, ⌘W close, ⌘Q quit to every window. Without it ⌘V doesn't paste in text fields.
- Esc closes the panel (`cancelOperation`); also show an explicit × button for mouse users.
- Position: on the screen with the mouse, horizontally centred, upper third. Remember a dragged position only if the user dragged it.
- **Dragging a borderless window**: `isMovableByWindowBackground` doesn't work over SwiftUI controls; put a drag-area `NSView` (overriding `mouseDown` → `window.performDrag(with:)`) behind the toolbar row.
- **Settings from a menu bar app**: switch to `.regular` while settings is open (otherwise it can open behind other apps and never take focus), activate, `makeKeyAndOrderFront`, then `makeFirstResponder(nil)`. Back to `.accessory` in `windowWillClose`. Close the panel first so keys don't fall through to it.
- **Reopen**: `applicationShouldHandleReopen` shows settings, so double-clicking the app in Finder or Launchpad visibly does something.
- **First launch**: show settings once (`didOnboard`), because a menu bar app is otherwise invisible.

## Window apps

- Regular activation, `NSWindow` with `.fullSizeContentView` and transparent title bar for a modern look, `setFrameAutosaveName` to remember size/position, a sensible `minSize`.
- `applicationShouldTerminateAfterLastWindowClosed` → false (Mac convention for single-window utilities) and reopen the main window from the Dock (`applicationShouldHandleReopen` with `!hasVisibleWindows`).
- Standard menus: App (About, Check for Updates, Settings ⌘,, Quit), File (New/Open if documents), Edit, View (Toggle sidebar ⌃⌘S if any), Window (Close ⌘W, Minimize ⌘M, main window ⌘0), Help (links to README).
- Sidebar + detail: `NavigationSplitView` inside the hosting view; keep selection in a model object, not in the view.
- Documents: if the app edits files, prefer plain files in a user-chosen folder with security-scoped bookmarks if sandboxed; autosave, never a "Save" step for small apps.

## Global hotkeys

- Use KeyboardShortcuts (sindresorhus). `KeyboardShortcuts.Name` with a default; `onKeyUp(for:)` to toggle. Recorder in settings.
- Recorder focus: never auto-focus it (the first key press would be captured). Settings calls `makeFirstResponder(nil)` on open and on tab change.
- When a recorder changes a shortcut that was registered with a handler, call `removeHandler(for:)` before re-registering, or both fire.
- Several shortcuts: keep them few (one global plus optional per-scene), show them in menus, and detect conflicts with the system (⌘Space, ⌃Space input switching).

## Launch at login

`SMAppService.mainApp.register()`; menu bar apps default it on, window apps off. Re-register at launch if the pref is on and status isn't `.enabled` (moving the app breaks the registration). Read the real status back after toggling; registration can fail silently.

## Data and state

- Prefs: one `Prefs` enum wrapping UserDefaults with typed keys and defaults in one place.
- Content: plain files the user owns. Atomic writes. Never lose input on a failed save: keep the text and show the error with a "重试 / 换个位置" action.
- History/recents: cap the size, filter temp paths, and switch it off during the self-test.
- Background work: `Task.detached` for disk/network, publish results on the main actor. No `DispatchQueue.main.sync`.

## Self-test and snapshot modes

`main.swift` checks `CommandLine.arguments` before `app.run()`: `--selftest` runs deterministic checks and exits with a status code; `--snapshot out.png` renders a SwiftUI view offscreen with the real fonts and appearance. Both are what let an agent verify work without clicking.

import AppKit
import SwiftUI
import KeyboardShortcuts
import ServiceManagement

// __NAME_ZH__ (__NAME__): app scaffold from qiaomu-macos-dev (AppInfo.menuBar picks the shape).
// Proven patterns baked in: non-activating floating panel, real main menu (⌘, ⌘W ⌘Q and Edit keys),
// settings as a regular window while open, launch at login, Sparkle, --snapshot / --selftest modes.

enum AppInfo {
    static let name = "__NAME_ZH__"
    static let englishName = "__NAME__"
    /// true: menu bar icon + hotkey panel, no Dock icon (LSUIElement). false: normal Dock app with a main window.
    static let menuBar = __MENUBAR__
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev" }
}

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.space, modifiers: [.option]))
}

/// A floating panel that never activates the app (the user's app keeps focus).
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    var onCancel: (() -> Void)?
    override func cancelOperation(_ sender: Any?) { onCancel?() }

    /// A non-activating panel skips the menu key-equivalent pass for whatever has focus; run it for every ⌘ chord.
    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, event.modifierFlags.contains(.command), performKeyEquivalent(with: event) { return }
        super.sendEvent(event)
    }

    override func performKeyEquivalent(with e: NSEvent) -> Bool {
        if super.performKeyEquivalent(with: e) { return true }
        let mods = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = e.charactersIgnoringModifiers?.lowercased() ?? ""
        if mods == .command && key == "q" { return true }               // never quit from the panel
        if mods == .command && key == "w" { onCancel?(); return true }
        return NSApp.mainMenu?.performKeyEquivalent(with: e) ?? false
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel?
    private var settingsWindow: NSWindow?
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ n: Notification) {
        Theme.registerFonts()
        installMainMenu()
        Updater.shared.start()
        guard AppInfo.menuBar else {                                       // window app: Dock icon + main window
            NSApp.setActivationPolicy(.regular)
            showMainWindow()
            return
        }
        NSApp.setActivationPolicy(.accessory)
        if UserDefaults.standard.object(forKey: "launchAtLogin") as? Bool ?? true, SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()                          // on by default, re-applied after moves
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "__SYMBOL__", accessibilityDescription: AppInfo.name)
        let menu = NSMenu()
        menu.delegate = self                                              // rebuilt on open
        statusItem.menu = menu

        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in self?.togglePanel() }

        if !UserDefaults.standard.bool(forKey: "didOnboard") {            // a menu bar app has no window: show settings once
            UserDefaults.standard.set(true, forKey: "didOnboard")
            showSettings()
        }
    }

    /// Opening the app again from Finder / Launchpad shows settings, so it never looks like "nothing happened".
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if AppInfo.menuBar { showSettings() } else if !flag { showMainWindow() }
        return true
    }

    /// Window app: closing the last window keeps the app alive (Mac convention); clicking the Dock icon reopens it.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    @objc func showMainWindow() {
        if mainWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 720, height: 480),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.title = AppInfo.name
            w.titlebarAppearsTransparent = true
            w.contentView = NSHostingView(rootView: MainView())
            w.minSize = NSSize(width: 520, height: 360)
            w.isReleasedWhenClosed = false
            w.setFrameAutosaveName("MainWindow")                             // remembers size and position
            if !w.setFrameUsingName("MainWindow") { w.center() }
            mainWindow = w
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
    }

    // MARK: Menus

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let open = menu.addItem(withTitle: "打开面板", action: #selector(togglePanel), keyEquivalent: "")
        open.target = self
        open.setShortcut(for: .togglePanel)
        menu.addItem(.separator())
        menu.addItem(withTitle: "设置…", action: #selector(showSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "检查更新…", action: #selector(Updater.checkForUpdates), keyEquivalent: "").target = Updater.shared
        menu.addItem(withTitle: "关于 \(AppInfo.name)", action: #selector(showAbout), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出 \(AppInfo.name)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    /// Invisible for a menu bar app, but it gives every window ⌘, ⌘W ⌘Q and the Edit shortcuts.
    private func installMainMenu() {
        let main = NSMenu()
        func submenu(_ title: String, _ items: [NSMenuItem]) {
            let holder = NSMenuItem(); let m = NSMenu(title: title)
            items.forEach(m.addItem); holder.submenu = m; main.addItem(holder)
        }
        func item(_ t: String, _ a: Selector, _ k: String, _ mods: NSEvent.ModifierFlags = .command, target: AnyObject? = nil) -> NSMenuItem {
            let i = NSMenuItem(title: t, action: a, keyEquivalent: k); i.keyEquivalentModifierMask = mods; i.target = target; return i
        }
        submenu(AppInfo.name, [
            item("关于 \(AppInfo.name)", #selector(showAbout), "", target: self),
            item("检查更新…", #selector(Updater.checkForUpdates), "", target: Updater.shared),
            .separator(),
            item("设置…", #selector(showSettings), ",", target: self),
            .separator(),
            item("退出 \(AppInfo.name)", #selector(NSApplication.terminate(_:)), "q"),
        ])
        submenu("编辑", [
            item("撤销", Selector(("undo:")), "z"), item("重做", Selector(("redo:")), "z", [.command, .shift]), .separator(),
            item("剪切", #selector(NSText.cut(_:)), "x"), item("拷贝", #selector(NSText.copy(_:)), "c"),
            item("粘贴", #selector(NSText.paste(_:)), "v"), item("全选", #selector(NSText.selectAll(_:)), "a"),
        ])
        var windowItems = [item("关闭", #selector(NSWindow.performClose(_:)), "w"),
                           item("最小化", #selector(NSWindow.performMiniaturize(_:)), "m")]
        if !AppInfo.menuBar { windowItems.append(item("主窗口", #selector(showMainWindow), "0", target: self)) }
        submenu("窗口", windowItems)
        NSApp.mainMenu = main
    }

    // MARK: Panel

    @objc func togglePanel() {
        if let p = panel, p.isVisible { closePanel(); return }
        let host = NSHostingView(rootView: PanelView(onClose: { [weak self] in self?.closePanel() }))
        let size = host.fittingSize
        let p = FloatingPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel],
                              backing: .buffered, defer: false)
        let container = NSView(frame: NSRect(origin: .zero, size: size))
        container.wantsLayer = true
        container.layer?.cornerRadius = Theme.radius; container.layer?.cornerCurve = .continuous; container.layer?.masksToBounds = true
        host.frame = container.bounds; host.autoresizingMask = [.width, .height]
        container.addSubview(host)
        p.contentView = container
        p.onCancel = { [weak self] in self?.closePanel() }
        p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true
        p.level = .floating
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.hidesOnDeactivate = false; p.isReleasedWhenClosed = false
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let f = screen?.visibleFrame { p.setFrameTopLeftPoint(NSPoint(x: f.midX - size.width / 2, y: f.minY + f.height * 0.68)) }
        panel = p
        p.makeKeyAndOrderFront(nil)
    }

    private func closePanel() { panel?.orderOut(nil); panel = nil }

    // MARK: Settings

    @objc func showAbout() { openSettings(tab: "关于") }

    @objc func showSettings() {
        if settingsWindow == nil { settingsWindow = SettingsWindow.make(); settingsWindow?.delegate = self }
        if panel?.isVisible == true { closePanel() }                    // key presses must not fall through to it
        NSApp.setActivationPolicy(.regular)                              // a menu bar app can't reliably take focus otherwise (no-op for window apps)
        if #available(macOS 14, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.makeFirstResponder(nil)                          // never auto-focus a shortcut recorder
    }

    private func openSettings(tab label: String) {
        showSettings()
        if let tabs = settingsWindow?.contentViewController as? NSTabViewController,
           let i = tabs.tabViewItems.firstIndex(where: { $0.label == label }) { tabs.selectedTabViewItemIndex = i }
    }

    func windowWillClose(_ notification: Notification) {
        if AppInfo.menuBar, (notification.object as? NSWindow) === settingsWindow { NSApp.setActivationPolicy(.accessory) }
    }
}

// MARK: - Offscreen snapshot (design review) and self-test

/// `__NAME__ --snapshot out.png [--dark] [--settings general|about|main]`: render a view the way it ships.
func snapshot(_ path: String, dark: Bool, settingsTab: String?) {
    Theme.registerFonts()
    let view: AnyView = switch settingsTab {
    case "general": AnyView(GeneralSettings())
    case "about": AnyView(AboutSettings())
    case "main": AnyView(MainView().frame(width: 720, height: 480))
    default: AnyView(PanelView(onClose: {}))
    }
    let host = NSHostingView(rootView: view)
    host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    host.frame = NSRect(origin: .zero, size: host.fittingSize)
    RunLoop.main.run(until: Date().addingTimeInterval(0.4))             // let async layout settle
    host.frame = NSRect(origin: .zero, size: host.fittingSize)
    let bg = NSView(frame: host.frame.insetBy(dx: -30, dy: -30))
    bg.wantsLayer = true
    bg.layer?.backgroundColor = (dark ? NSColor(white: 0.12, alpha: 1) : NSColor(white: 0.93, alpha: 1)).cgColor
    host.frame.origin = NSPoint(x: 30, y: 30)
    bg.addSubview(host)
    let rep = bg.bitmapImageRepForCachingDisplay(in: bg.bounds)!
    bg.cacheDisplay(in: bg.bounds, to: rep)
    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
}

/// `__NAME__ --selftest`: deterministic checks of the app's logic. Grow it with every feature.
func selftest() -> Int32 {
    var failures = 0
    func check(_ name: String, _ got: String, _ want: String) {
        let ok = got == want
        if !ok { failures += 1 }
        print(ok ? "✓" : "✗", name, ok ? "" : "→ got \(got.debugDescription), want \(want.debugDescription)")
    }
    check("app name", AppInfo.name, "__NAME_ZH__")
    print(failures == 0 ? "ALL PASS" : "\(failures) FAILED")
    return failures == 0 ? 0 : 1
}

let args = CommandLine.arguments
if args.contains("--selftest") { _ = NSApplication.shared; exit(selftest()) }
if let i = args.firstIndex(of: "--snapshot"), i + 1 < args.count {
    _ = NSApplication.shared
    snapshot(args[i + 1], dark: args.contains("--dark"), settingsTab: args.firstIndex(of: "--settings").map { args[$0 + 1] })
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

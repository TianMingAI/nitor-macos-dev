import SwiftUI
import AppKit
import KeyboardShortcuts
import ServiceManagement

/// Standard macOS preferences: toolbar tabs, title follows the tab ("App · 通用"), nothing auto-focused.
final class SettingsTabs: NSTabViewController {
    override func tabView(_ tabView: NSTabView, didSelect item: NSTabViewItem?) {
        super.tabView(tabView, didSelect: item)
        view.window?.title = "\(AppInfo.name) · \(item?.label ?? "设置")"
        view.window?.makeFirstResponder(nil)
    }
}

enum SettingsWindow {
    static func make() -> NSWindow {
        let tabs = SettingsTabs()
        tabs.tabStyle = .toolbar
        tabs.canPropagateSelectedChildViewControllerTitle = false
        func tab<V: View>(_ title: String, _ symbol: String, _ view: V) {
            let host = NSHostingController(rootView: view)
            host.sizingOptions = [.preferredContentSize]
            let item = NSTabViewItem(viewController: host)
            item.label = title
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)
            tabs.addTabViewItem(item)
        }
        tab("通用", "gearshape", GeneralSettings())
        tab("关于", "info.circle", AboutSettings())
        let w = NSWindow(contentViewController: tabs)
        w.styleMask = [.titled, .closable]
        w.toolbarStyle = .preference
        w.title = "\(AppInfo.name) · 通用"
        w.initialFirstResponder = nil
        w.isReleasedWhenClosed = false
        w.center()
        return w
    }
}

struct GeneralSettings: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            if AppInfo.menuBar {
                Section("快捷键") {
                    KeyboardShortcuts.Recorder("打开面板", name: .togglePanel)
                }
            }
            Section {
                Toggle("登录时自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { on in
                        do { on ? try SMAppService.mainApp.register() : try SMAppService.mainApp.unregister() }
                        catch { launchAtLogin = SMAppService.mainApp.status == .enabled }
                        UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: AppInfo.menuBar ? 260 : 150)
    }
}

enum Links {
    static let repo = URL(string: "https://github.com/__REPO__")!
    static let issues = URL(string: "https://github.com/__REPO__/issues/new")!
    static let readme = URL(string: "https://github.com/__REPO__#readme")!
}

/// About: icon, version, actions, follow/tip QR cards (bundled, works offline), links, privacy line, license.
struct AboutSettings: View {
    @State private var autoUpdate = Updater.shared.automaticallyChecks

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(AppInfo.name).font(.system(size: 20, weight: .semibold))
                        Text("\(AppInfo.englishName) \(AppInfo.version)").font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
                    }
                    Text("__TAGLINE__").font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                AboutButton("检查更新", "arrow.triangle.2.circlepath") { Updater.shared.checkForUpdates() }
                AboutButton("反馈问题", "ladybug") { NSWorkspace.shared.open(Links.issues) }
                AboutButton("使用说明", "book") { NSWorkspace.shared.open(Links.readme) }
                AboutButton("源代码", "chevron.left.forwardslash.chevron.right") { NSWorkspace.shared.open(Links.repo) }
            }
            Toggle("自动检查更新（有新版时轻提示，不打断你）", isOn: $autoUpdate)
                .toggleStyle(.checkbox).font(.system(size: 12)).foregroundStyle(.secondary)
                .onChange(of: autoUpdate) { Updater.shared.automaticallyChecks = $0 }
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 14) {
                QRCard(image: "wechat-qr.jpg", title: "关注公众号", symbol: "newspaper", hint: "微信搜索「向阳乔木推荐看」")
                QRCard(image: "reward-qr.png", title: "请我喝杯咖啡", symbol: "cup.and.saucer", hint: "微信扫码，支持持续更新")
            }
            VStack(spacing: 8) {
                HStack(spacing: 14) {
                    ForEach([("qiaomu.ai", "https://qiaomu.ai/"), ("博客", "https://blog.qiaomu.ai/"), ("乔木推荐", "https://tuijian.qiaomu.ai/"),
                             ("X", "https://x.com/vista8"), ("GitHub", "https://github.com/joeseesun")], id: \.0) { item in
                        Link(item.0, destination: URL(string: item.1)!).font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.primary.opacity(0.75))
                    }
                }
                Text("数据只保存在本机。").font(.system(size: 11)).foregroundStyle(.secondary)
                Text("© \(String(Calendar.current.component(.year, from: Date()))) 向阳乔木 · MIT 许可 · 第三方许可见 THIRD_PARTY_NOTICES.md")
                    .font(.system(size: 11)).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 24)
        .frame(width: 520)
    }
}

private struct AboutButton: View {
    let title: String, symbol: String, action: () -> Void
    @State private var hover = false
    init(_ title: String, _ symbol: String, action: @escaping () -> Void) { self.title = title; self.symbol = symbol; self.action = action }
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol).font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity).frame(height: 30)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(hover ? 0.09 : 0.05)))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.primary.opacity(0.08)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain).onHover { hover = $0 }
    }
}

private struct QRCard: View {
    let image: String, title: String, symbol: String, hint: String
    var body: some View {
        VStack(spacing: 10) {
            Group {
                if let url = Bundle.main.resourceURL?.appendingPathComponent("About/\(image)"), let img = NSImage(contentsOf: url) {
                    Image(nsImage: img).resizable().interpolation(.high).scaledToFit()
                } else { Color.primary.opacity(0.05) }
            }
            .frame(width: 128, height: 128).padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            VStack(spacing: 3) {
                Label(title, systemImage: symbol).font(.system(size: 13, weight: .semibold))
                Text(hint).font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.07)))
    }
}

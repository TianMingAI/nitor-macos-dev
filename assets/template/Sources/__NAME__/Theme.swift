import SwiftUI
import AppKit

/// Design tokens: Vercel-style black/white, Geist for Latin with PingFang for CJK. One accent at most.
enum Theme {
    private static func dyn(_ light: NSColor, _ dark: NSColor) -> NSColor {
        NSColor(name: nil) { $0.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light }
    }
    private static func hex(_ v: UInt32, _ a: CGFloat = 1) -> NSColor {
        NSColor(srgbRed: CGFloat(v >> 16 & 0xff) / 255, green: CGFloat(v >> 8 & 0xff) / 255, blue: CGFloat(v & 0xff) / 255, alpha: a)
    }
    static let background = Color(nsColor: dyn(hex(0xFFFFFF), hex(0x0A0A0A)))
    static let bar = Color(nsColor: dyn(hex(0xFAFAFA), hex(0x111111)))
    static let border = Color(nsColor: dyn(hex(0xEAEAEA), hex(0x262626)))
    static let text = Color(nsColor: dyn(hex(0x0A0A0A), hex(0xEDEDED)))
    static let muted = Color(nsColor: dyn(hex(0x666666), hex(0xA1A1A1)))
    static let subtle = Color(nsColor: dyn(hex(0x8F8F8F), hex(0x6E6E6E)))
    static let hover = Color(nsColor: dyn(hex(0x000000, 0.05), hex(0xFFFFFF, 0.07)))
    static let inverse = background
    static let radius: CGFloat = 12

    static func sans(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom(weight == .semibold ? "Geist-SemiBold" : weight == .medium ? "Geist-Medium" : "Geist-Regular", size: size)
    }

    /// Bundled fonts in Resources/Fonts (Geist is SIL OFL; ship its license). Missing fonts fall back to the system font.
    static func registerFonts() {
        guard let dir = Bundle.main.resourceURL?.appendingPathComponent("Fonts"),
              let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for f in files where f.pathExtension == "ttf" { CTFontManagerRegisterFontsForURL(f as CFURL, .process, nil) }
    }
}

/// Starter panel: replace with the app's real content. Keep the explicit close button and Esc.
struct PanelView: View {
    let onClose: () -> Void
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(AppInfo.name).font(Theme.sans(15, .semibold)).foregroundStyle(Theme.text)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark").font(.system(size: 10, weight: .semibold)).foregroundStyle(Theme.subtle)
                        .frame(width: 24, height: 24).contentShape(Circle())
                }
                .buttonStyle(.plain).help("关闭（Esc）")
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)
            TextField("", text: $text, prompt: Text("__TAGLINE__"))
                .textFieldStyle(.plain).font(Theme.sans(17)).padding(.horizontal, 20).padding(.bottom, 18)
            Rectangle().fill(Theme.border).frame(height: 1)
            HStack {
                Text("Esc 关闭").font(Theme.sans(12)).foregroundStyle(Theme.subtle)
                Spacer()
                Button { onClose() } label: {
                    Text("完成").font(Theme.sans(13, .medium)).foregroundStyle(Theme.inverse)
                        .padding(.horizontal, 12).frame(height: 30)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Theme.text))
                }
                .buttonStyle(.plain).keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 20).frame(height: 52).background(Theme.bar)
        }
        .frame(width: 560)
        .background(Theme.background)
        .overlay(RoundedRectangle(cornerRadius: Theme.radius, style: .continuous).strokeBorder(Theme.border))
    }
}

/// Starter main window for `--kind window` apps: replace with the real UI (sidebar + detail, document, etc.).
/// Keeps the Vercel look: generous whitespace, one primary action, empty state that says what to do next.
struct MainView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 72, height: 72)
            Text(AppInfo.name).font(Theme.sans(22, .semibold)).foregroundStyle(Theme.text)
            Text("__TAGLINE__").font(Theme.sans(13)).foregroundStyle(Theme.muted)
            Button {} label: {
                Text("开始").font(Theme.sans(13, .medium)).foregroundStyle(Theme.inverse)
                    .padding(.horizontal, 16).frame(height: 32)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Theme.text))
            }
            .buttonStyle(.plain).keyboardShortcut(.defaultAction).padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
    }
}

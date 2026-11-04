import SwiftUI
import AppKit

/// Small non-activating notice at the top of the screen with optional actions ("已保存  撤销").
enum Toast {
    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let run: () -> Void
    }
    enum Style { case success, warning }

    private static var panel: NSPanel?
    private static var hideWork: DispatchWorkItem?

    static func show(_ title: String, detail: String? = nil, style: Style = .success,
                     actions: [Action] = [], duration: TimeInterval = 3) {
        dismiss()
        let view = ToastView(title: title, detail: detail, style: style,
                             actions: actions.map { a in Action(title: a.title) { dismiss(); a.run() } },
                             onHover: { $0 ? hideWork?.cancel() : schedule(1.6) })
        let host = NSHostingView(rootView: view)
        let size = host.fittingSize
        let p = NSPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        p.contentView = host
        p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true
        p.level = .statusBar
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        p.isReleasedWhenClosed = false
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
        if let f = screen?.visibleFrame { p.setFrameOrigin(NSPoint(x: f.midX - size.width / 2, y: f.maxY - size.height - 14)) }
        p.orderFrontRegardless()
        panel = p
        schedule(duration)
    }

    private static func schedule(_ delay: TimeInterval) {
        hideWork?.cancel()
        let w = DispatchWorkItem { dismiss() }
        hideWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: w)
    }

    static func dismiss() {
        hideWork?.cancel()
        panel?.orderOut(nil)
        panel = nil
    }
}

private struct ToastView: View {
    let title: String
    let detail: String?
    let style: Toast.Style
    let actions: [Toast.Action]
    let onHover: (Bool) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: style == .success ? "checkmark" : "exclamationmark")
                .font(.system(size: 9, weight: .heavy)).foregroundStyle(Theme.inverse)
                .frame(width: 18, height: 18)
                .background(Circle().fill(style == .success ? Theme.text : Color.orange))
            Text(title).font(Theme.sans(13, .medium)).foregroundStyle(Theme.text)
            if let detail { Text(detail).font(Theme.sans(12)).foregroundStyle(Theme.muted).lineLimit(1) }
            ForEach(actions) { a in
                Button(a.title, action: a.run).buttonStyle(.plain)
                    .font(Theme.sans(12, .medium)).foregroundStyle(Theme.muted).padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 14).frame(height: 40)
        .background(Capsule().fill(Theme.background))
        .overlay(Capsule().strokeBorder(Theme.border))
        .padding(1)
        .onHover(perform: onHover)
    }
}

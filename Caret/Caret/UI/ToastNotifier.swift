import AppKit
import SwiftUI

/// Top-right floating toast that auto-dismisses after a short delay.
/// Same panel configuration as `SuggestionPanel` (non-activating,
/// floating, focus-safe). Reused across calls — only one toast at a
/// time; a new `show` cancels and replaces the previous one.
@MainActor
final class ToastNotifier {
    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    func show(_ message: String, duration: Duration = .seconds(2)) {
        let panel = ensurePanel()
        let host = NSHostingView(rootView: ToastView(message: message))
        host.translatesAutoresizingMaskIntoConstraints = true
        panel.contentView = host

        let size = host.fittingSize
        if let screen = NSScreen.main ?? NSScreen.screens.first {
            let origin = NSPoint(
                x: screen.visibleFrame.maxX - size.width - 16,
                y: screen.visibleFrame.maxY - size.height - 16
            )
            panel.setFrame(NSRect(origin: origin, size: size), display: true)
        }
        panel.orderFrontRegardless()

        hideTask?.cancel()
        hideTask = Task { [weak self] in
            do { try await Task.sleep(for: duration) } catch { return }
            self?.panel?.orderOut(nil)
        }
    }

    private func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.panel = panel
        return panel
    }
}

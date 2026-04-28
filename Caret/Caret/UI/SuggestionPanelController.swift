import AppKit
import Combine
import SwiftUI

/// Owns the floating `SuggestionPanel` lifecycle. Subscribes to the
/// coordinator's published state, anchors the panel to the AX caret
/// rectangle, and hides as soon as the user keeps typing past the
/// suggested span.
@MainActor
final class SuggestionPanelController {
    private let coordinator: InputCoordinator
    private var panel: SuggestionPanel?
    private var hostingView: NSHostingView<SuggestionView>?
    /// The exact text the LLM saw when the visible suggestion was produced.
    /// Used to dismiss the panel as soon as the user diverges from it.
    private var anchoredText: String?
    private var cancellables: Set<AnyCancellable> = []

    init(coordinator: InputCoordinator) {
        self.coordinator = coordinator
    }

    func start() {
        coordinator.$lastCorrection
            .removeDuplicates()
            .sink { [weak self] state in
                Task { @MainActor in self?.handle(correction: state) }
            }
            .store(in: &cancellables)

        coordinator.$lastContext
            .sink { [weak self] context in
                Task { @MainActor in self?.handle(context: context) }
            }
            .store(in: &cancellables)
    }

    private func handle(correction: CorrectionState?) {
        guard
            case .completed(let response) = correction,
            response.shouldCorrect,
            !response.corrected.isEmpty,
            let fire = coordinator.lastFire,
            let context = coordinator.lastContext,
            context.text == fire.context.text
        else {
            hide()
            return
        }
        anchoredText = fire.context.text
        present(corrected: response.corrected, caretRect: fire.context.caretScreenRect)
    }

    private func handle(context: FocusedContext?) {
        guard let anchored = anchoredText else { return }
        if let context, context.text == anchored { return }
        hide()
    }

    private func present(corrected: String, caretRect: CGRect?) {
        let panel = ensurePanel()
        let host = ensureHostingView(in: panel)
        host.rootView = SuggestionView(corrected: corrected)

        let size = host.fittingSize
        let origin = computeOrigin(panelSize: size, axCaret: caretRect)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()
    }

    private func hide() {
        anchoredText = nil
        panel?.orderOut(nil)
    }

    private func ensurePanel() -> SuggestionPanel {
        if let panel { return panel }
        let panel = SuggestionPanel()
        self.panel = panel
        return panel
    }

    private func ensureHostingView(in panel: SuggestionPanel) -> NSHostingView<SuggestionView> {
        if let host = hostingView { return host }
        let host = NSHostingView(rootView: SuggestionView(corrected: ""))
        host.translatesAutoresizingMaskIntoConstraints = true
        panel.contentView = host
        hostingView = host
        return host
    }

    private func computeOrigin(panelSize: NSSize, axCaret: CGRect?) -> NSPoint {
        if let caret = axCaret, caret.width > 0 || caret.height > 0 {
            return positionAboveCaret(panelSize: panelSize, axCaret: caret)
        }
        return degradedPosition(panelSize: panelSize)
    }

    private func positionAboveCaret(panelSize: NSSize, axCaret: CGRect) -> NSPoint {
        let primary =
            NSScreen.screens.first(where: { $0.frame.origin == .zero })
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let primary else { return .zero }
        let primaryTop = primary.frame.maxY
        // AX uses top-left origin relative to the primary screen; flip to NS coordinates.
        let nsCaretBottom = primaryTop - axCaret.maxY
        let nsCaretTop = primaryTop - axCaret.minY

        let centerNS = NSPoint(x: axCaret.midX, y: nsCaretTop)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(centerNS) }) ?? primary

        var originY = nsCaretTop + 8
        if originY + panelSize.height > screen.visibleFrame.maxY {
            originY = nsCaretBottom - panelSize.height - 8
        }

        var originX = axCaret.midX - panelSize.width / 2
        let minX = screen.visibleFrame.minX + 8
        let maxX = screen.visibleFrame.maxX - panelSize.width - 8
        originX = max(minX, min(originX, maxX))

        return NSPoint(x: originX, y: originY)
    }

    private func degradedPosition(panelSize: NSSize) -> NSPoint {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return .zero }
        return NSPoint(
            x: screen.visibleFrame.maxX - panelSize.width - 16,
            y: screen.visibleFrame.maxY - panelSize.height - 16
        )
    }
}

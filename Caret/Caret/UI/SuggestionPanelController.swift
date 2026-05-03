import AppKit
import Combine
import SwiftUI
import os

/// Owns the floating `SuggestionPanel` lifecycle. Subscribes to the
/// coordinator's published state, anchors the panel to the AX caret
/// rectangle, and hides as soon as the user keeps typing past the
/// suggested span.
@MainActor
final class SuggestionPanelController {
    private let coordinator: InputCoordinator
    private let toast = ToastNotifier()
    private var panel: SuggestionPanel?
    private var hostingView: NSHostingView<SuggestionView>?
    /// The exact text the LLM saw when the visible suggestion was produced.
    /// Used to dismiss the panel as soon as the user diverges from it.
    private var anchoredText: String?
    private var activeAccept: (fire: TriggerFire, response: CorrectionResponse)?
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

        coordinator.acceptRequests
            .sink { [weak self] in
                Task { @MainActor in self?.accept() }
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
        activeAccept = (fire: fire, response: response)
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
        coordinator.acceptArmed.arm()
    }

    private func hide() {
        coordinator.acceptArmed.disarm()
        anchoredText = nil
        activeAccept = nil
        panel?.orderOut(nil)
    }

    /// Applies the visible suggestion via AX. Step 3 will fall back to
    /// the pasteboard when AX setValue fails (Electron / web apps).
    private func accept() {
        guard let active = activeAccept else { return }
        let response = active.response

        guard
            let element = AXHelpers.focusedElement(),
            let bundle = AXHelpers.bundleID(of: element),
            bundle == active.fire.context.bundleID
        else {
            Log.capture.notice("accept aborted: focus changed")
            hide()
            return
        }

        guard
            let span = Self.findSpan(
                of: response.original,
                in: active.fire.context.text,
                near: active.fire.context.cursorRange.location
            )
        else {
            Log.capture.notice("accept aborted: original not found in text")
            hide()
            return
        }

        guard
            AXHelpers.setRange(span, attribute: kAXSelectedTextRangeAttribute, of: element)
        else {
            Log.capture.notice("accept: setRange refused, copy to pasteboard for manual paste")
            copyToPasteboardOnly(response.corrected)
            toast.show("Copied — paste with ⌘V")
            hide()
            return
        }

        Self.replaceSelection(with: response.corrected)
        Log.capture.notice("accept ok (paste)")
        hide()
    }

    /// Copies `text` to the pasteboard, synthesizes a ⌘V keystroke via
    /// `CGEvent.post`, and schedules a pasteboard restore. Works in
    /// every app that respects standard paste (native, Electron, web)
    /// because we go through the OS clipboard rather than relying on
    /// each app's AX `setValue` implementation.
    private static func replaceSelection(with text: String) {
        let pasteboard = NSPasteboard.general
        let saved = pasteboard.string(forType: .string)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 0x09
        let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        down?.flags = .maskCommand
        up?.flags = .maskCommand
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard let saved else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(saved, forType: .string)
        }
    }

    private func copyToPasteboardOnly(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Finds `needle` inside `haystack` and returns the UTF-16 range of
    /// the occurrence closest to `cursor`. Nil if `needle` is empty or
    /// not found.
    private static func findSpan(
        of needle: String,
        in haystack: String,
        near cursor: Int
    ) -> NSRange? {
        guard !needle.isEmpty else { return nil }
        let nsHaystack = haystack as NSString
        var ranges: [NSRange] = []
        var searchRange = NSRange(location: 0, length: nsHaystack.length)
        while searchRange.location < nsHaystack.length {
            let found = nsHaystack.range(of: needle, options: [], range: searchRange)
            if found.location == NSNotFound { break }
            ranges.append(found)
            searchRange.location = found.location + max(found.length, 1)
            searchRange.length = nsHaystack.length - searchRange.location
        }
        guard !ranges.isEmpty else { return nil }
        return ranges.min(by: { abs($0.location - cursor) < abs($1.location - cursor) })
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
        if let elementFrame = focusedElementFrame() {
            return positionAboveCaret(panelSize: panelSize, axCaret: elementFrame)
        }
        return degradedPosition(panelSize: panelSize)
    }

    private func focusedElementFrame() -> CGRect? {
        guard let element = AXHelpers.focusedElement() else { return nil }
        guard let frame = AXHelpers.frame(of: element) else { return nil }
        guard frame.width > 0, frame.height > 0 else { return nil }
        return frame
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

        // Anchor to the left edge of the focused rect (matches Copilot/iA Writer
        // behavior — user reads the suggestion left-to-right starting where they type).
        var originX = axCaret.minX
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

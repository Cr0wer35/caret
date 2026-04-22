import AppKit
import ApplicationServices

/// A snapshot of the focused text field as read through the Accessibility API.
struct FocusedContext: Sendable, Equatable {
    let text: String
    let cursorRange: NSRange
    let caretScreenRect: CGRect?
    let bundleID: String?
}

/// Reads the focused text field via AX. Runs on its own actor so the
/// synchronous AX IPC calls never block the main thread.
actor TextCapture {
    func focusedContext() -> FocusedContext? {
        guard
            let element = AXHelpers.focusedElement(),
            !AXHelpers.isSecure(element),
            let text = AXHelpers.string(kAXValueAttribute, of: element)
        else { return nil }

        let cursor =
            AXHelpers.range(kAXSelectedTextRangeAttribute, of: element)
            ?? NSRange(location: text.utf16.count, length: 0)

        let caretRect = AXHelpers.bounds(
            for: NSRange(location: cursor.location, length: max(1, cursor.length)),
            in: element
        )

        return FocusedContext(
            text: text,
            cursorRange: cursor,
            caretScreenRect: caretRect,
            bundleID: AXHelpers.bundleID(of: element)
        )
    }
}

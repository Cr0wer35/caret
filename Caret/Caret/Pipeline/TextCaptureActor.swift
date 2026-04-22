import AppKit
import ApplicationServices

/// A snapshot of the focused text field as read through the Accessibility API.
struct FocusedContext: Sendable, Equatable {
    let text: String
    let cursorRange: NSRange
    let caretScreenRect: CGRect?
    let bundleID: String?
}

/// Result of one capture attempt. The `unavailable` case covers no focus,
/// secure text fields, and AX read failures — the caller cannot tell
/// them apart (intentional: either way, we skip the correction).
enum CaptureOutcome: Sendable, Equatable {
    case captured(FocusedContext)
    case blocked(bundleID: String)
    case unavailable
}

/// Reads the focused text field via AX. Runs on its own actor so the
/// synchronous AX IPC calls never block the main thread.
actor TextCapture {
    let denylist: Denylist

    init(denylist: Denylist = .default) {
        self.denylist = denylist
    }

    func capture() -> CaptureOutcome {
        guard let element = AXHelpers.focusedElement() else { return .unavailable }
        guard !AXHelpers.isSecure(element) else { return .unavailable }

        let bundleID = AXHelpers.bundleID(of: element)
        if let bundleID, denylist.contains(bundleID) {
            return .blocked(bundleID: bundleID)
        }

        guard let text = AXHelpers.string(kAXValueAttribute, of: element) else {
            return .unavailable
        }

        let cursor =
            AXHelpers.range(kAXSelectedTextRangeAttribute, of: element)
            ?? NSRange(location: text.utf16.count, length: 0)

        let caretRect = AXHelpers.bounds(
            for: NSRange(location: cursor.location, length: max(1, cursor.length)),
            in: element
        )

        return .captured(
            FocusedContext(
                text: text,
                cursorRange: cursor,
                caretScreenRect: caretRect,
                bundleID: bundleID
            )
        )
    }
}

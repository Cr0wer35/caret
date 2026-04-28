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

        let caretRect = Self.caretBounds(for: cursor, in: element, textLength: text.utf16.count)

        return .captured(
            FocusedContext(
                text: text,
                cursorRange: cursor,
                caretScreenRect: caretRect,
                bundleID: bundleID
            )
        )
    }

    /// Computes a usable rect for the caret. AX rejects ranges past
    /// the end of text, so when the cursor sits at the very end we
    /// fall back to the last visible character.
    private static func caretBounds(
        for cursor: NSRange,
        in element: AXUIElement,
        textLength: Int
    ) -> CGRect? {
        if cursor.length > 0 {
            return AXHelpers.bounds(for: cursor, in: element)
        }
        if cursor.location < textLength {
            let forward = AXHelpers.bounds(
                for: NSRange(location: cursor.location, length: 1),
                in: element
            )
            if let forward { return forward }
        }
        if cursor.location > 0 {
            return AXHelpers.bounds(
                for: NSRange(location: cursor.location - 1, length: 1),
                in: element
            )
        }
        return nil
    }
}

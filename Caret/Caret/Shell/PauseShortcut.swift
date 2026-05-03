import AppKit

/// User-configurable pause/resume hotkey. Stored as raw `(keyCode,
/// modifierBits)` so we can serialize it to `UserDefaults` without
/// dragging in a custom `Codable` for `NSEvent.ModifierFlags`.
struct PauseShortcut: Codable, Sendable, Equatable {
    var keyCode: UInt16
    var modifierBits: UInt

    static let `default` = PauseShortcut(
        keyCode: 0x08,
        modifierBits: NSEvent.ModifierFlags([.command, .option]).rawValue
    )

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierBits)
    }

    /// Symbolic display string, e.g. `⌥⌘C` — matches macOS menu bar
    /// notation. Used by the menu bar item and the recorder UI.
    var displayString: String {
        var result = ""
        let flags = modifierFlags
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option) { result += "⌥" }
        if flags.contains(.shift) { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        result += Self.keyCodeSymbol(keyCode)
        return result
    }

    /// Best-effort symbolic name for a virtual key code. Falls back to
    /// `?` when we don't have a curated mapping; the recorder UI shows
    /// the captured key correctly through the system, this is just for
    /// pretty display in the menu bar.
    private static func keyCodeSymbol(_ keyCode: UInt16) -> String {
        Self.keyCodeMap[keyCode] ?? "?"
    }

    private static let keyCodeMap: [UInt16: String] = [
        0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H", 0x05: "G",
        0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V", 0x0B: "B", 0x0C: "Q",
        0x0D: "W", 0x0E: "E", 0x0F: "R", 0x10: "Y", 0x11: "T", 0x1F: "O",
        0x20: "U", 0x22: "I", 0x23: "P", 0x25: "L", 0x26: "J", 0x28: "K",
        0x2D: "N", 0x2E: "M",
        0x30: "⇥", 0x31: "Space", 0x33: "⌫", 0x35: "⎋",
        0x7B: "←", 0x7C: "→", 0x7D: "↓", 0x7E: "↑",
    ]
}

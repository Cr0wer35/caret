import Foundation

/// Apps Caret refuses to read from. Checked before any AX read, so no
/// text ever leaves these apps — not even to local logging.
///
/// `nonisolated` + `Sendable` so the `TextCapture` actor can hold it
/// off-main without isolation hops.
nonisolated struct Denylist: Sendable, Equatable {
    let bundleIDs: Set<String>

    func contains(_ bundleID: String) -> Bool {
        bundleIDs.contains(bundleID)
    }

    /// `UserDefaults` key shared with `DenylistStore`. Read from
    /// anywhere via `Denylist.current()`.
    static let storageKey = "caret.denylist"

    /// Snapshot of the current persisted list, falling back to
    /// `.default` when the key is missing or empty. Thread-safe —
    /// `UserDefaults` reads are safe from any actor.
    static func current(defaults: UserDefaults = .standard) -> Denylist {
        let stored = defaults.stringArray(forKey: storageKey) ?? []
        let set = Set(stored)
        return set.isEmpty ? .default : Denylist(bundleIDs: set)
    }

    /// Hardcoded defaults. Extend via Settings → Privacy, not by editing here.
    static let `default` = Denylist(bundleIDs: [
        // Password managers
        "com.1password.1password",
        "com.1password.1password8",
        "com.agilebits.onepassword7",
        "com.apple.Passwords",
        "com.bitwarden.desktop",
        "com.dashlane.5",
        "com.lastpass.LastPass",
        // Terminals
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "co.zeit.hyperterm",
        "io.alacritty",
        "net.kovidgoyal.kitty",
    ])
}

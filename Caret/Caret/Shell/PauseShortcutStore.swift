import Combine
import Foundation

/// Mutable, observable store for the user's pause/resume hotkey.
/// Backed by a JSON blob in `UserDefaults`. Defaults to `⌥⌘C`.
@MainActor
final class PauseShortcutStore: ObservableObject {
    @Published var shortcut: PauseShortcut { didSet { persist() } }

    private let defaults: UserDefaults
    private static let storageKey = "caret.pauseShortcut"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.shortcut = Self.load(from: defaults) ?? .default
    }

    private static func load(from defaults: UserDefaults) -> PauseShortcut? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(PauseShortcut.self, from: data)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}

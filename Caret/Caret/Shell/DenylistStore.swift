import Combine
import Foundation

/// Mutable, observable wrapper around the persisted denylist. The
/// underlying data lives in `UserDefaults`; `Denylist.current()`
/// reads it from anywhere (including off-main from `TextCapture`),
/// so changes flow through automatically on the next capture.
@MainActor
final class DenylistStore: ObservableObject {
    @Published private(set) var bundleIDs: [String]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = Set(defaults.stringArray(forKey: Denylist.storageKey) ?? [])
        let initial = stored.isEmpty ? Denylist.default.bundleIDs : stored
        self.bundleIDs = initial.sorted()
    }

    func add(_ bundleID: String) {
        let trimmed = bundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !bundleIDs.contains(trimmed) else { return }
        var next = Set(bundleIDs)
        next.insert(trimmed)
        commit(next)
    }

    func remove(_ bundleID: String) {
        var next = Set(bundleIDs)
        next.remove(bundleID)
        commit(next)
    }

    func resetToDefault() {
        commit(Denylist.default.bundleIDs)
    }

    private func commit(_ next: Set<String>) {
        bundleIDs = next.sorted()
        defaults.set(bundleIDs, forKey: Denylist.storageKey)
    }
}

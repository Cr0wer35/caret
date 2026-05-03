import Foundation
import os.lock

/// Thread-safe boolean the `CGEventTap` C callback reads synchronously
/// to decide whether the next plain `Tab` should be swallowed.
///
/// `OSAllocatedUnfairLock` is Sendable and provides a lock-protected
/// sync read, which is exactly what the C callback context needs (it
/// can't `await` an actor before returning).
nonisolated final class AcceptArmedFlag: Sendable {
    private let storage = OSAllocatedUnfairLock<Bool>(initialState: false)

    var isArmed: Bool {
        storage.withLock { $0 }
    }

    func arm() {
        storage.withLock { $0 = true }
    }

    func disarm() {
        storage.withLock { $0 = false }
    }
}

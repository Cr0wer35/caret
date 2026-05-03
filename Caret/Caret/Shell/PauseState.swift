import Combine
import Foundation

/// Process-wide pause flag. When `isPaused` is `true`, the
/// `InputCoordinator` skips all capture/correction work and the
/// suggestion panel hides itself.
///
/// `@MainActor` because every observer is a SwiftUI view or a
/// MainActor-bound coordinator. State changes are intentionally
/// trivial — no work to defer to a background actor.
@MainActor
final class PauseState: ObservableObject {
    @Published private(set) var isPaused = false

    func toggle() {
        isPaused.toggle()
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
    }
}

import Foundation

/// Why the engine decided to fire a correction request.
enum TriggerReason: String, Sendable, Equatable {
    case wordCount
    case sentenceBoundary
}

/// One fire decision — context snapshot at the moment of firing.
struct TriggerFire: Sendable, Equatable {
    let context: FocusedContext
    let reason: TriggerReason
    let at: Date
}

/// Debounces raw keystroke-driven captures into a small stream of
/// "ready to correct" fires. Rule: fire when
/// `(newWords ≥ threshold OR text ends in sentence punctuation)` AND
/// `idle ≥ threshold`.
///
/// Off-main actor: caller awaits `evaluate(_:)` after every capture;
/// the engine replies asynchronously via the `onFire` callback.
actor TriggerEngine {
    private let idleThreshold: Duration
    private let newWordsThreshold: Int
    private let sentenceEndings: Set<Character> = [".", "!", "?"]

    private var lastWordCount = 0
    private var newWordsSinceLastFire = 0
    private var lastContext: FocusedContext?
    private var lastEndsInBoundary = false
    private var idleTask: Task<Void, Never>?

    private let onFire: @Sendable (TriggerFire) -> Void

    init(
        idleThreshold: Duration = .milliseconds(400),
        newWordsThreshold: Int = 3,
        onFire: @escaping @Sendable (TriggerFire) -> Void
    ) {
        self.idleThreshold = idleThreshold
        self.newWordsThreshold = newWordsThreshold
        self.onFire = onFire
    }

    /// Feed a fresh capture. Resets the idle timer.
    func evaluate(_ context: FocusedContext) {
        let bundleChanged = (lastContext?.bundleID != context.bundleID)
        let currentWords = Self.wordCount(context.text)

        if bundleChanged {
            // Focus switched apps or fields — don't carry over counters.
            newWordsSinceLastFire = 0
            lastWordCount = currentWords
        } else {
            let delta = currentWords - lastWordCount
            if delta > 0 {
                newWordsSinceLastFire += delta
            } else if delta < 0 {
                newWordsSinceLastFire = 0
            }
            lastWordCount = currentWords
        }

        lastEndsInBoundary = context.text.last.map { sentenceEndings.contains($0) } ?? false
        lastContext = context

        idleTask?.cancel()
        let threshold = idleThreshold
        idleTask = Task { [weak self] in
            do { try await Task.sleep(for: threshold) } catch { return }
            await self?.checkIdle()
        }
    }

    private func checkIdle() {
        guard let ctx = lastContext, newWordsSinceLastFire > 0 else { return }
        if lastEndsInBoundary {
            fire(ctx, reason: .sentenceBoundary)
            return
        }
        if newWordsSinceLastFire >= newWordsThreshold {
            fire(ctx, reason: .wordCount)
        }
    }

    private func fire(_ context: FocusedContext, reason: TriggerReason) {
        newWordsSinceLastFire = 0
        onFire(TriggerFire(context: context, reason: reason, at: Date()))
    }

    nonisolated private static func wordCount(_ text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
    }
}

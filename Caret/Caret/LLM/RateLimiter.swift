import Foundation

/// Token-bucket rate limiter shared across providers. Refills smoothly
/// at `perMinute / 60` tokens per second up to `capacity`. Each
/// `take()` consumes one token; when the bucket is empty, callers get
/// `LLMError.rateLimited` immediately rather than waiting.
actor RateLimiter {
    private let capacity: Double
    private let refillPerSecond: Double
    private var tokens: Double
    private var lastRefill: Date

    init(capacity: Int = 30, perMinute: Int = 30) {
        self.capacity = Double(capacity)
        self.refillPerSecond = Double(perMinute) / 60
        self.tokens = Double(capacity)
        self.lastRefill = Date()
    }

    func take(now: Date = Date()) throws {
        refill(now: now)
        guard tokens >= 1 else {
            throw LLMError.rateLimited
        }
        tokens -= 1
    }

    private func refill(now: Date) {
        let elapsed = now.timeIntervalSince(lastRefill)
        guard elapsed > 0 else { return }
        tokens = min(capacity, tokens + elapsed * refillPerSecond)
        lastRefill = now
    }
}

import CryptoKit
import Foundation

/// In-memory LRU + TTL cache for correction responses. The key is a
/// SHA-256 hash of `provider:model:text`, so identical inputs against
/// the same model are deduplicated within a session.
///
/// Bounded to 100 entries and 10 minutes by default. Drops the oldest
/// touched entry on overflow.
actor CorrectionCache {
    private struct Entry {
        let response: CorrectionResponse
        let storedAt: Date
    }

    private var entries: [String: Entry] = [:]
    private var accessOrder: [String] = []
    private let maxEntries: Int
    private let ttl: TimeInterval

    init(maxEntries: Int = 100, ttl: TimeInterval = 600) {
        self.maxEntries = maxEntries
        self.ttl = ttl
    }

    func get(_ key: String, now: Date = Date()) -> CorrectionResponse? {
        guard let entry = entries[key] else { return nil }
        if now.timeIntervalSince(entry.storedAt) > ttl {
            entries.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
            return nil
        }
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        return entry.response
    }

    func set(_ key: String, _ response: CorrectionResponse, now: Date = Date()) {
        entries[key] = Entry(response: response, storedAt: now)
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        while accessOrder.count > maxEntries {
            let oldest = accessOrder.removeFirst()
            entries.removeValue(forKey: oldest)
        }
    }

    nonisolated static func key(provider: String, model: String, text: String) -> String {
        let composite = "\(provider):\(model):\(text)"
        let digest = SHA256.hash(data: Data(composite.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

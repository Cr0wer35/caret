import Foundation
import Security

enum KeychainError: Error, Equatable {
    case notFound
    case unexpectedData
    case osStatus(OSStatus)
}

/// Thin wrapper around the Keychain Services API. One UTF-8 string
/// value per `account`, scoped to Caret's service identifier.
///
/// `nonisolated` + `Sendable`-friendly: Keychain calls are thread-safe,
/// so any actor can read/write without hopping to the main thread.
nonisolated enum KeychainStore {
    private static let service = "com.caret.Caret"

    static func set(_ value: String, for account: String) throws {
        let data = Data(value.utf8)
        let base = baseQuery(for: account)

        let updateStatus = SecItemUpdate(
            base as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = base
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.osStatus(addStatus) }
        default:
            throw KeychainError.osStatus(updateStatus)
        }
    }

    static func get(_ account: String) throws -> String {
        var query = baseQuery(for: account)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
                throw KeychainError.unexpectedData
            }
            return string
        case errSecItemNotFound:
            throw KeychainError.notFound
        default:
            throw KeychainError.osStatus(status)
        }
    }

    static func delete(_ account: String) throws {
        let status = SecItemDelete(baseQuery(for: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.osStatus(status)
        }
    }

    static func has(_ account: String) -> Bool {
        (try? get(account)) != nil
    }

    private static func baseQuery(for account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

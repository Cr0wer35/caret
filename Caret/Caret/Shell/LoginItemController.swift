import Combine
import Foundation

/// Observable wrapper around `LoginItem` for SwiftUI bindings. Keeps
/// the toggle in sync with the actual `SMAppService` state and
/// surfaces the last error (e.g. unsigned binary) so the General
/// tab can show it inline.
@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var lastError: String?

    init() {
        self.isEnabled = LoginItem.isEnabled
    }

    func setEnabled(_ value: Bool) {
        do {
            try LoginItem.setEnabled(value)
            lastError = nil
        } catch {
            lastError = "Couldn't update login item: \(error.localizedDescription)"
        }
        isEnabled = LoginItem.isEnabled
    }
}

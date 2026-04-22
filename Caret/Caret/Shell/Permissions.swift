import AppKit
import ApplicationServices
import Combine

enum PermissionStatus: Equatable, Sendable {
    case granted
    case denied
}

@MainActor
final class PermissionsMonitor: ObservableObject {
    @Published private(set) var status: PermissionStatus
    private var pollingTask: Task<Void, Never>?

    init() {
        self.status = AXIsProcessTrusted() ? .granted : .denied
    }

    func start() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                let fresh: PermissionStatus = AXIsProcessTrusted() ? .granted : .denied
                if fresh != self.status {
                    self.status = fresh
                }
            }
        }
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    static func openSystemSettings() {
        let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        )!
        NSWorkspace.shared.open(url)
    }
}

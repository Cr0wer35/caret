import Foundation

/// Bundle metadata read from `Info.plist`. Static accessors so views
/// don't need to thread a Bundle reference around.
nonisolated enum AppVersion {
    static var marketing: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    /// Display string like `0.1.0 (12)`.
    static var displayString: String {
        "\(marketing) (\(build))"
    }
}

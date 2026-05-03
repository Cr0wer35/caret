import ServiceManagement

/// Thin wrapper over `SMAppService.mainApp` so the rest of the app
/// doesn't import `ServiceManagement`. Calls are synchronous and
/// thread-safe per Apple's docs.
nonisolated enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Toggles the "Open at Login" entry. Throws on Apple's underlying
    /// error so callers can surface it (typically only fails if the app
    /// bundle is unsigned or moved after first registration).
    static func setEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}

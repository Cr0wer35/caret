import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissions = PermissionsMonitor()
    let textCapture = TextCapture()
    let providerStore = ProviderStore()
    lazy var inputCoordinator = InputCoordinator(
        textCapture: textCapture,
        providerStore: providerStore
    )
    lazy var debugOverlay = DebugOverlayWindowController(coordinator: inputCoordinator)
    lazy var settingsController = SettingsWindowController(store: providerStore)
    lazy var suggestionPanel = SuggestionPanelController(coordinator: inputCoordinator)
    private var onboardingController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        permissions.start()

        let controller = OnboardingWindowController(permissions: permissions)
        onboardingController = controller
        controller.showIfNeeded()

        if permissions.status == .granted {
            inputCoordinator.start()
        }

        suggestionPanel.start()
    }

    func reopenOnboarding() {
        onboardingController?.show()
    }

    func toggleDebugOverlay() {
        debugOverlay.toggle()
    }

    func showSettings() {
        settingsController.show()
    }
}

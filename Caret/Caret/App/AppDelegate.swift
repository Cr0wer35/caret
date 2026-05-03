import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissions = PermissionsMonitor()
    let textCapture = TextCapture()
    let providerStore = ProviderStore()
    let pauseState = PauseState()
    let pauseShortcutStore = PauseShortcutStore()
    let dailyCounter = DailyCounter()
    let denylistStore = DenylistStore()
    let loginItem = LoginItemController()
    lazy var connectionTester = ConnectionTester(store: providerStore)
    lazy var globalShortcutMonitor = GlobalShortcutMonitor(
        store: pauseShortcutStore,
        onTrigger: { [weak self] in self?.pauseState.toggle() }
    )
    lazy var inputCoordinator = InputCoordinator(
        textCapture: textCapture,
        providerStore: providerStore,
        pauseState: pauseState
    )
    lazy var debugOverlay = DebugOverlayWindowController(coordinator: inputCoordinator)
    lazy var settingsController = SettingsWindowController(
        providerStore: providerStore,
        shortcutStore: pauseShortcutStore,
        denylistStore: denylistStore,
        loginItem: loginItem,
        connectionTester: connectionTester
    )
    lazy var suggestionPanel = SuggestionPanelController(
        coordinator: inputCoordinator,
        pauseState: pauseState,
        dailyCounter: dailyCounter
    )
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
        globalShortcutMonitor.start()
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

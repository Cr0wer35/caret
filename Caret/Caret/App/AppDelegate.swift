import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissions = PermissionsMonitor()
    let textCapture = TextCapture()
    lazy var inputCoordinator = InputCoordinator(textCapture: textCapture)
    lazy var debugOverlay = DebugOverlayWindowController(coordinator: inputCoordinator)
    private var onboardingController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        permissions.start()

        let controller = OnboardingWindowController(permissions: permissions)
        onboardingController = controller
        controller.showIfNeeded()

        if permissions.status == .granted {
            inputCoordinator.start()
        }
    }

    func reopenOnboarding() {
        onboardingController?.show()
    }

    func toggleDebugOverlay() {
        debugOverlay.toggle()
    }
}

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissions = PermissionsMonitor()
    private var onboardingController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        permissions.start()

        let controller = OnboardingWindowController(permissions: permissions)
        onboardingController = controller
        controller.showIfNeeded()
    }

    func reopenOnboarding() {
        onboardingController?.show()
    }
}

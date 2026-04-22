import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let permissions = PermissionsMonitor()
    let textCapture = TextCapture()
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

    /// M2a debug scaffold: triggers one AX capture and logs the result.
    /// Removed in M2b when the CGEventTap drives captures automatically.
    func performDebugCapture() {
        Task { [textCapture] in
            // Let the menu dismiss and the previous app regain focus before
            // reading the AX tree, otherwise we read Caret's own menu state.
            try? await Task.sleep(for: .milliseconds(150))
            guard let ctx = await textCapture.focusedContext() else {
                let msg = "focusedContext: nil (no focus, secure field, or AX read failed)"
                Log.capture.notice("\(msg, privacy: .public)")
                print("[capture]", msg)
                return
            }
            let rect = ctx.caretScreenRect.map { String(describing: $0) } ?? "nil"
            let msg = """
                bundle=\(ctx.bundleID ?? "nil") \
                cursor=\(ctx.cursorRange.location)+\(ctx.cursorRange.length) \
                caretRect=\(rect) \
                text=\(ctx.text.prefix(120))
                """
            Log.capture.notice("\(msg, privacy: .public)")
            print("[capture]", msg)
        }
    }
}

import AppKit
import Combine

/// Listens for the user's pause hotkey from any focused app.
///
/// Uses `NSEvent.addGlobalMonitorForEvents` for keystrokes from other
/// apps (Accessibility permission required, which we already have)
/// plus `addLocalMonitorForEvents` so the shortcut also works when
/// Caret's own settings window is key. Re-binds whenever the stored
/// shortcut changes.
@MainActor
final class GlobalShortcutMonitor {
    private let store: PauseShortcutStore
    private let onTrigger: @MainActor () -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var subscription: AnyCancellable?

    init(store: PauseShortcutStore, onTrigger: @escaping @MainActor () -> Void) {
        self.store = store
        self.onTrigger = onTrigger
    }

    func start() {
        rebind()
        subscription = store.$shortcut
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor in self?.rebind() }
            }
    }

    func stop() {
        if let global = globalMonitor { NSEvent.removeMonitor(global) }
        if let local = localMonitor { NSEvent.removeMonitor(local) }
        globalMonitor = nil
        localMonitor = nil
        subscription = nil
    }

    private func rebind() {
        if let global = globalMonitor { NSEvent.removeMonitor(global) }
        if let local = localMonitor { NSEvent.removeMonitor(local) }
        let shortcut = store.shortcut

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let bits = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            guard keyCode == shortcut.keyCode, bits == shortcut.modifierBits else { return }
            Task { @MainActor [weak self] in self?.onTrigger() }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let bits = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            if keyCode == shortcut.keyCode, bits == shortcut.modifierBits {
                Task { @MainActor [weak self] in self?.onTrigger() }
                return nil
            }
            return event
        }
    }
}

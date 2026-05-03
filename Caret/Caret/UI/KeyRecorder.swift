import AppKit
import Combine
import SwiftUI

/// One-shot key capture button. Click to enter "recording" mode, then
/// press the desired keystroke. The captured key+modifiers update the
/// bound `PauseShortcut`. Escape cancels.
struct KeyRecorder: View {
    @Binding var shortcut: PauseShortcut
    @StateObject private var model = KeyRecorderModel()

    var body: some View {
        Button(action: { model.toggle(setting: $shortcut) }, label: { label })
            .buttonStyle(.plain)
            .onDisappear { model.stop() }
    }

    private var label: some View {
        Text(model.isRecording ? "Press a key…" : shortcut.displayString)
            .font(.system(size: 12, weight: .medium))
            .frame(minWidth: 90, alignment: .center)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(
                        model.isRecording
                            ? Color.accentColor : Color.secondary.opacity(0.4),
                        lineWidth: model.isRecording ? 1 : 0.5
                    )
            )
    }
}

@MainActor
private final class KeyRecorderModel: ObservableObject {
    @Published var isRecording = false
    private var monitor: Any?

    func toggle(setting binding: Binding<PauseShortcut>) {
        if isRecording {
            stop()
        } else {
            start(setting: binding)
        }
    }

    func stop() {
        isRecording = false
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    private func start(setting binding: Binding<PauseShortcut>) {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // Escape cancels recording.
            if event.keyCode == 0x35 {
                Task { @MainActor in self.stop() }
                return nil
            }
            // Ignore events that carry no real key (pure modifier presses).
            let chars = event.charactersIgnoringModifiers ?? ""
            guard !chars.isEmpty else { return nil }
            let keyCode = event.keyCode
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            Task { @MainActor in
                binding.wrappedValue = PauseShortcut(keyCode: keyCode, modifierBits: flags)
                self.stop()
            }
            return nil
        }
    }
}

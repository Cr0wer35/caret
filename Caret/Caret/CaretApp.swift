import SwiftUI

@main
struct CaretApp: App {
    var body: some Scene {
        MenuBarExtra("Caret", systemImage: "pencil.tip") {
            Text("Caret — v0.1.0-dev")
                .font(.caption)
            Divider()
            Button("Quit Caret") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}

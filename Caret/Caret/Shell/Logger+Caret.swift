import os

/// Centralized `os.Logger` categories for Caret. One logger per subsystem area.
nonisolated enum Log {
    static let capture = Logger(subsystem: "com.caret.Caret", category: "capture")
}

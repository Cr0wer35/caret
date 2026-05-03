import Foundation

/// One slot in the settings nav bar.
enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case provider
    case privacy
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .provider: "AI Provider"
        case .privacy: "Privacy"
        case .about: "About"
        }
    }

    var systemImage: String {
        switch self {
        case .general: "gearshape.fill"
        case .provider: "bolt.fill"
        case .privacy: "hand.raised.fill"
        case .about: "info.circle.fill"
        }
    }
}

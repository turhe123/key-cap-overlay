import Foundation
import Carbon.HIToolbox

/// UserDefaults keys and default values shared by `@AppStorage` and the services.
enum Prefs {
    static let enabled = "enabled"
    static let mode = "mode"
    static let position = "position"
    static let showClicks = "showClicks"
    static let fadeDelay = "fadeDelay"
    static let keySize = "keySize"
    static let textSize = "textSize"
    static let colorScheme = "colorScheme"
    static let opacity = "opacity"
    static let display = "display"
    static let hotKeyCode = "hotKeyCode"
    static let hotKeyMods = "hotKeyMods"
    static let hotKeyLabel = "hotKeyLabel"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            enabled: true, mode: DisplayMode.all.rawValue, position: OverlayPosition.bottomCenter.rawValue,
            showClicks: false, fadeDelay: 1.5, keySize: 1.0, textSize: 24.0,
            colorScheme: ChipScheme.dark.rawValue, opacity: 0.9, display: 0,
            hotKeyCode: kVK_ANSI_K, hotKeyMods: controlKey | optionKey, hotKeyLabel: "⌃⌥K",
        ])
    }

    static var defaults: UserDefaults { .standard }
}

/// Which key presses are shown.
enum DisplayMode: String, CaseIterable, Identifiable {
    case all, shortcuts
    var id: String { rawValue }
    var title: String { self == .all ? "All Keys" : "Shortcuts Only" }
}

/// Where the overlay sits on screen.
enum OverlayPosition: String, CaseIterable, Identifiable {
    case bottomCenter, bottomLeft, bottomRight, topCenter, followActive
    var id: String { rawValue }
    var title: String {
        switch self {
        case .bottomCenter: "Bottom Center"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .topCenter: "Top Center"
        case .followActive: "Follow Active Screen"
        }
    }
}

/// Keycap color schemes.
enum ChipScheme: String, CaseIterable, Identifiable {
    case light, dark, accent
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

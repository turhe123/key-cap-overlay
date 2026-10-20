import SwiftUI
import AppKit

/// Entry point: a menu-bar-only app with a settings window.
@main
struct KeyCapOverlayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("KeyCapOverlay", systemImage: "keyboard") {
            MenuContent()
        }
        Window("KeyCapOverlay Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
    }
}

/// Boots the long-lived services once AppKit has finished launching.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Prefs.registerDefaults()
        KeystrokeController.shared.start()
    }
}

/// Opens the donation page in the default browser.
enum Support {
    static func open() {
        NSWorkspace.shared.open(URL(string: "https://ko-fi.com/leodavidai")!)
    }
}

/// The menu shown from the menu bar keyboard icon.
struct MenuContent: View {
    @ObservedObject private var permissions = PermissionState.shared
    @Environment(\.openWindow) private var openWindow
    @AppStorage(Prefs.enabled) private var enabled = true
    @AppStorage(Prefs.mode) private var mode = DisplayMode.all.rawValue
    @AppStorage(Prefs.position) private var position = OverlayPosition.bottomCenter.rawValue
    @AppStorage(Prefs.showClicks) private var showClicks = false

    var body: some View {
        if !permissions.trusted {
            Button("⚠️ Grant Accessibility Access…") { permissions.openSystemSettings() }
            Text("Needed to see key presses. Nothing is ever recorded.")
            Divider()
        }
        Toggle("Show Keystrokes", isOn: $enabled)
        Picker("Mode", selection: $mode) {
            ForEach(DisplayMode.allCases) { Text($0.title).tag($0.rawValue) }
        }
        Picker("Position", selection: $position) {
            ForEach(OverlayPosition.allCases) { Text($0.title).tag($0.rawValue) }
        }
        Toggle("Show Mouse Clicks", isOn: $showClicks)
        Divider()
        Button("Settings…") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")
        Button("Support / Donate ❤️") { Support.open() }
        Divider()
        Button("Quit KeyCapOverlay") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }
}

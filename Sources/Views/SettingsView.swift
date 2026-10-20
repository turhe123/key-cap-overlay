import SwiftUI
import AppKit
import ServiceManagement

/// Settings window: appearance, display, login item, hotkey and privacy note.
struct SettingsView: View {
    @AppStorage(Prefs.fadeDelay) private var fadeDelay = 1.5
    @AppStorage(Prefs.keySize) private var keySize = 1.0
    @AppStorage(Prefs.textSize) private var textSize = 24.0
    @AppStorage(Prefs.colorScheme) private var scheme = ChipScheme.dark.rawValue
    @AppStorage(Prefs.opacity) private var opacity = 0.9
    @AppStorage(Prefs.display) private var display = 0
    @AppStorage(Prefs.mode) private var mode = DisplayMode.all.rawValue
    @AppStorage(Prefs.showClicks) private var showClicks = false
    @ObservedObject private var permissions = PermissionState.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            if !permissions.trusted {
                Section {
                    Label("Accessibility access is required to show keystrokes.", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Button("Grant Access…") { permissions.openSystemSettings() }
                }
            }
            Section("Behavior") {
                Picker("Mode", selection: $mode) {
                    ForEach(DisplayMode.allCases) { Text($0.title).tag($0.rawValue) }
                }
                LabeledContent("Fade delay") {
                    HStack {
                        Slider(value: $fadeDelay, in: 0.5...5, step: 0.5)
                        TextField("", value: $fadeDelay, format: .number.precision(.fractionLength(1)))
                            .frame(width: 44)
                        Text("s")
                    }
                }
                Toggle("Show mouse click badges", isOn: $showClicks)
            }
            Section("Appearance") {
                Slider(value: $keySize, in: 0.6...2) { Text("Keycap size") }
                Slider(value: $textSize, in: 12...56) { Text("Text size") }
                Slider(value: $opacity, in: 0.3...1) { Text("Opacity") }
                Picker("Color scheme", selection: $scheme) {
                    ForEach(ChipScheme.allCases) { Text($0.title).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                Picker("Display", selection: $display) {
                    Text("Main display").tag(0)
                    ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { i, screen in
                        Text(screen.localizedName).tag(i + 1)
                    }
                }
                KeycapView(chip: Chip(text: "⌘⇧4", isWord: false), keySize: keySize, textSize: textSize,
                           scheme: ChipScheme(rawValue: scheme) ?? .dark)
                    .opacity(opacity)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, on in setLaunchAtLogin(on) }
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.red) }
                LabeledContent("Toggle hotkey") { HotKeyRecorder() }
            }
            Section {
                Label("Keystrokes are only shown on screen. They are never written to disk or sent over the network.",
                      systemImage: "lock.shield")
                    .font(.callout)
                Button("Support / Donate ❤️") { Support.open() }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Could not update login item: \(error.localizedDescription)"
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

/// Records a new global toggle shortcut (needs ⌘, ⌃ or ⌥; Esc cancels).
struct HotKeyRecorder: View {
    @AppStorage(Prefs.hotKeyLabel) private var label = "⌃⌥K"
    @State private var monitor: Any?

    var body: some View {
        Button(monitor == nil ? label : "Press shortcut…") {
            monitor == nil ? start() : stop()
        }
        .onDisappear { stop() }
    }

    private func start() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
            if event.keyCode == 53 { stop(); return nil }
            guard !flags.intersection([.command, .control, .option]).isEmpty,
                  let key = KeyGlyphs.keyName(code: Int(event.keyCode), event: event) else { return nil }
            let defaults = Prefs.defaults
            defaults.set(Int(event.keyCode), forKey: Prefs.hotKeyCode)
            defaults.set(KeyGlyphs.carbonModifiers(flags), forKey: Prefs.hotKeyMods)
            label = KeyGlyphs.modifiers(flags) + key
            NotificationCenter.default.post(name: HotKey.changed, object: nil)
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

import AppKit
import ApplicationServices

/// Tracks the Accessibility trust state; prompts once, then polls gently until granted.
final class PermissionState: ObservableObject {
    static let shared = PermissionState()
    @Published private(set) var trusted = AXIsProcessTrusted()
    private var timer: Timer?

    /// Prompts once and calls `onGranted` as soon as access is available.
    func ensureTrusted(onGranted: @escaping () -> Void) {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        trusted = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if trusted { onGranted(); return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] t in
            guard let self, AXIsProcessTrusted() else { return }
            self.trusted = true
            t.invalidate()
            onGranted()
        }
    }

    func openSystemSettings() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

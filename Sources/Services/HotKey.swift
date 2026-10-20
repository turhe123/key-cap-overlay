import Carbon.HIToolbox
import Foundation

/// Registers the global on/off hotkey through Carbon `RegisterEventHotKey`.
final class HotKey {
    static let shared = HotKey()
    static let changed = Notification.Name("KeyCapOverlayHotKeyChanged")
    var action: () -> Void = {}
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?

    func register(keyCode: Int, modifiers: Int) {
        if let ref { UnregisterEventHotKey(ref); self.ref = nil }
        if handler == nil {
            var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                DispatchQueue.main.async { HotKey.shared.action() }
                return noErr
            }, 1, &spec, nil, &handler)
        }
        let id = EventHotKeyID(signature: OSType(0x4B434F56), id: 1)
        let status = RegisterEventHotKey(UInt32(keyCode), UInt32(modifiers), id, GetApplicationEventTarget(), 0, &ref)
        if status != noErr { NSLog("KeyCapOverlay: hotkey registration failed (\(status))") }
    }
}

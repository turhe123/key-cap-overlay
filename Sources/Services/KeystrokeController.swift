import AppKit
import Carbon.HIToolbox
import CoreGraphics

/// Owns the listen-only CGEventTap and turns raw events into overlay chips.
/// Keystrokes live only in memory; nothing is written to disk or sent anywhere.
final class KeystrokeController {
    static let shared = KeystrokeController()
    let model = OverlayModel()
    private lazy var overlay = OverlayPanelController(model: model)
    private let clicks = ClickBadgeController()
    private var tap: CFMachPort?
    private var pendingModifiers: NSEvent.ModifierFlags?
    private var secureTimer: Timer?
    private let defaults = Prefs.defaults

    func start() {
        HotKey.shared.action = { [weak self] in
            guard let self else { return }
            let on = !self.defaults.bool(forKey: Prefs.enabled)
            self.defaults.set(on, forKey: Prefs.enabled)
            self.model.clear()
            if on { self.model.add(text: "⌨︎ On", word: false) }
        }
        registerHotKey()
        NotificationCenter.default.addObserver(forName: HotKey.changed, object: nil, queue: .main) { [weak self] _ in
            self?.registerHotKey()
        }
        PermissionState.shared.ensureTrusted { [weak self] in self?.installTap() }
        // Pause the overlay entirely while a password field holds secure input.
        secureTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if IsSecureEventInputEnabled() || !self.defaults.bool(forKey: Prefs.enabled) { self.model.clear() }
        }
        _ = overlay
    }

    private func registerHotKey() {
        HotKey.shared.register(keyCode: defaults.integer(forKey: Prefs.hotKeyCode),
                               modifiers: defaults.integer(forKey: Prefs.hotKeyMods))
    }

    private func installTap() {
        guard tap == nil else { return }
        var mask: CGEventMask = 0
        for type in [CGEventType.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown] {
            mask |= 1 << CGEventMask(type.rawValue)
        }
        let callback: CGEventTapCallBack = { _, type, event, info in
            if let info {
                Unmanaged<KeystrokeController>.fromOpaque(info).takeUnretainedValue().handle(type: type, event: event)
            }
            return Unmanaged.passUnretained(event)
        }
        guard let port = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                                           eventsOfInterest: mask, callback: callback,
                                           userInfo: Unmanaged.passUnretained(self).toOpaque()) else {
            NSLog("KeyCapOverlay: could not create event tap; retrying shortly")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in self?.installTap() }
            return
        }
        tap = port
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
    }

    private func handle(type: CGEventType, event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard defaults.bool(forKey: Prefs.enabled), !IsSecureEventInputEnabled() else { return }
        switch type {
        case .keyDown: keyDown(event)
        case .flagsChanged: flagsChanged(event)
        case .leftMouseDown: click("L")
        case .rightMouseDown: click("R")
        case .otherMouseDown: click("M")
        default: break
        }
    }

    private func keyDown(_ cgEvent: CGEvent) {
        pendingModifiers = nil
        let code = Int(cgEvent.getIntegerValueField(.keyboardEventKeycode))
        let isRepeat = cgEvent.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let nsEvent = NSEvent(cgEvent: cgEvent)
        let flags = NSEvent.ModifierFlags(rawValue: UInt(cgEvent.flags.rawValue)).intersection([.command, .control, .option, .shift])
        let isShortcut = !flags.intersection([.command, .control, .option]).isEmpty
        let shortcutsOnly = defaults.string(forKey: Prefs.mode) == DisplayMode.shortcuts.rawValue

        if isShortcut {
            guard !isRepeat, let key = KeyGlyphs.keyName(code: code, event: nsEvent) else { return }
            model.add(text: KeyGlyphs.modifiers(flags) + key, word: false)
            return
        }
        guard !shortcutsOnly else { return }
        if isRepeat { model.touchLast(); return }
        // Plain typing: use the layout's real characters and merge them into a word chip.
        if code == kVK_Space, model.lastIsActiveWord {
            model.appendTyped(" ")
        } else if KeyGlyphs.special[code] == nil, let chars = nsEvent?.characters, !chars.isEmpty,
           chars.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }) {
            model.appendTyped(chars)
        } else if let key = KeyGlyphs.keyName(code: code, event: nsEvent) {
            model.add(text: KeyGlyphs.modifiers(flags) + key, word: false)
        }
    }

    /// Shows a lone modifier tap (e.g. ⌘ pressed and released) in All Keys mode.
    private func flagsChanged(_ cgEvent: CGEvent) {
        let flags = NSEvent.ModifierFlags(rawValue: UInt(cgEvent.flags.rawValue)).intersection([.command, .control, .option, .shift])
        if flags.isEmpty {
            if let pending = pendingModifiers, defaults.string(forKey: Prefs.mode) == DisplayMode.all.rawValue {
                model.add(text: KeyGlyphs.modifiers(pending), word: false)
            }
            pendingModifiers = nil
        } else {
            pendingModifiers = flags.union(pendingModifiers ?? [])
        }
    }

    private func click(_ label: String) {
        pendingModifiers = nil
        guard defaults.bool(forKey: Prefs.showClicks) else { return }
        clicks.show(label, at: NSEvent.mouseLocation)
    }
}

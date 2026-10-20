import AppKit
import SwiftUI

/// Borderless, click-through, non-activating panel that floats on every Space.
final class OverlayPanel: NSPanel {
    init(size: NSSize) {
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Positions the keystroke overlay and shows/hides it as chips come and go.
final class OverlayPanelController {
    private let panel = OverlayPanel(size: NSSize(width: 1000, height: 220))
    private let model: OverlayModel

    init(model: OverlayModel) {
        self.model = model
        panel.contentView = NSHostingView(rootView: OverlayView(model: model))
        model.onChange = { [weak self] in self?.refresh() }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification,
                                               object: nil, queue: .main) { [weak self] _ in self?.reposition() }
    }

    private func refresh() {
        if model.chips.isEmpty {
            // Let the fade-out animation finish before hiding the window.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                guard let self, self.model.chips.isEmpty else { return }
                self.panel.orderOut(nil)
            }
        } else {
            reposition()
            if !panel.isVisible { panel.orderFrontRegardless() }
        }
    }

    /// Chosen display, falling back to the main screen if it was unplugged.
    private func targetScreen(_ position: OverlayPosition) -> NSScreen? {
        if position == .followActive {
            let mouse = NSEvent.mouseLocation
            return NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        }
        let index = Prefs.defaults.integer(forKey: Prefs.display) - 1
        return NSScreen.screens.indices.contains(index) ? NSScreen.screens[index] : NSScreen.main
    }

    private func reposition() {
        let position = OverlayPosition(rawValue: Prefs.defaults.string(forKey: Prefs.position) ?? "") ?? .bottomCenter
        guard let screen = targetScreen(position) else { return }
        let area = screen.visibleFrame
        let size = NSSize(width: min(1000, area.width - 40), height: 220)
        let margin: CGFloat = 40
        let x: CGFloat
        switch position {
        case .bottomLeft: x = area.minX + margin
        case .bottomRight: x = area.maxX - margin - size.width
        default: x = area.midX - size.width / 2
        }
        let y = position == .topCenter ? area.maxY - size.height - margin / 2 : area.minY + margin
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: false)
    }
}

/// Briefly shows an L / R / M badge next to the pointer on mouse clicks.
final class ClickBadgeController {
    private let panel = OverlayPanel(size: NSSize(width: 34, height: 34))
    private let label = NSTextField(labelWithString: "")
    private var hideWork: DispatchWorkItem?

    init() {
        let box = NSView(frame: NSRect(x: 0, y: 0, width: 34, height: 34))
        box.wantsLayer = true
        box.layer?.cornerRadius = 17
        box.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.85).cgColor
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.alignment = .center
        label.frame = NSRect(x: 0, y: 7, width: 34, height: 20)
        box.addSubview(label)
        panel.contentView = box
    }

    func show(_ text: String, at point: NSPoint) {
        label.stringValue = text
        panel.setFrameOrigin(NSPoint(x: point.x + 14, y: point.y - 44))
        panel.alphaValue = 1
        panel.orderFrontRegardless()
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            NSAnimationContext.runAnimationGroup({ $0.duration = 0.25; self?.panel.animator().alphaValue = 0 },
                                                 completionHandler: { self?.panel.orderOut(nil) })
        }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }
}

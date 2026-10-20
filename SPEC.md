# KeyCapOverlay — specification

**Tagline:** Show every key and shortcut you press as clean keycaps floating on screen for demos, tutorials and recordings.

**Category:** Presentation & Cursor

**Inspired by (paid):** Keystroke Pro ($19.99 one-time)

**Frameworks:** SwiftUI, AppKit, CoreGraphics, ApplicationServices, ServiceManagement

**Donation URL (Support button):** https://ko-fi.com/leodavidai

## Spec

What the paid app does and evidence of demand. Keystroke Pro is a Mac App Store utility that draws the keys you press as keycap graphics on top of the screen, so viewers of a screencast, a livestream or a live demo can follow along. Store listings and Mac news sites list it around 19.99 dollars, and the free open source alternative KeyCastr gets recommended in almost every thread about showing keystrokes, which shows steady demand from tutorial makers, teachers and developers. Several cheaper clones also exist in the store, which confirms the need.

Feature set for our clean-room version. A menu bar app with a global on and off toggle. While on, each key press appears in a floating overlay as a rounded keycap with the symbol of the key. Modifier combinations such as Command Shift 4 are grouped into one compact badge. Two display modes: show every key, or show only shortcuts that include Command, Control or Option. Plain typing in password fields is skipped by detecting secure input mode and pausing the overlay while it is active. Keys fade out after a configurable delay, and a short run of typed letters is merged into a single word chip that grows as you type, then fades after a pause. Optional mouse click badges show left, right and middle clicks near the pointer.

UI spec. A MenuBarExtra with a keyboard icon. Menu items: Show Keystrokes toggle, Mode submenu (All keys, Shortcuts only), Position submenu (bottom center, bottom left, bottom right, top center, follow active screen), Settings, Quit. The settings window has fields for fade delay in seconds, keycap size slider, text size slider, color scheme picker (light, dark, accent), overlay opacity, display to use, launch at login toggle and a global hotkey recorder for the toggle with a default of Control Option K. The overlay is a borderless, click-through, non-activating NSPanel at floating level that joins all Spaces. Empty state: when nothing was pressed recently the overlay is completely invisible. When Accessibility permission is missing, the menu shows a prominent Grant Access item and a short explanation.

Technical approach. Observe keys with a listen-only CGEventTap on keyDown, flagsChanged and optional mouse down events, which requires the Input Monitoring or Accessibility permission. Check with AXIsProcessTrustedWithOptions and prompt once, then poll gently until granted. Translate key codes to display glyphs with a hand-written table for special keys such as Return, Delete, arrows and function keys, and use the event characters for letters. Detect secure input using IsSecureEventInputEnabled from the Carbon HIToolbox and hide the overlay while true. Render the overlay with a SwiftUI view hosted in an NSHostingView inside the panel, with a small observable model holding a list of recent chips with timestamps. Persist settings with AppStorage. Register launch at login with SMAppService main app. The global toggle hotkey can use a second tap or a Carbon RegisterEventHotKey registration.

Edge cases and error handling. If the event tap is disabled by the system because of a timeout, re-enable it from the tap callback on the disabled-by-timeout event type. Handle keyboard layouts other than US by using the characters produced by the event rather than raw key codes. Handle key repeat by ignoring repeated events for shortcuts and collapsing them for typed text. Limit the number of visible chips to a sane maximum such as eight. Move the overlay when displays change or the chosen display is unplugged. Never write keystrokes to disk or the network, and state this plainly in the settings window. Keep total code near 450 lines.

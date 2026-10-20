# KeyCapOverlay

Show every key and shortcut you press as clean keycaps floating on screen for demos, tutorials and recordings.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![License MIT](https://img.shields.io/badge/License-MIT-green)
![GitHub release](https://img.shields.io/github/v/release/turhe123/key-cap-overlay)

## Why

KeyCapOverlay is a free, open-source, 100% native, backend-free alternative to paid utilities in the *Presentation & Cursor* category. It was inspired by Keystroke Pro ($19.99 one-time), which shows the value of letting viewers follow along with what you type. KeyCapOverlay is a small menu bar app written in SwiftUI and AppKit, with no server, account or third-party code.

## Features

- **Menu bar app** (no Dock icon) with a "Show Keystrokes" toggle and a global hotkey to switch it on and off (default `⌃⌥K`, re-recordable in Settings).
- **Keycap overlay**: each key press appears as a rounded keycap. Modifier combinations such as `⌘⇧4` are grouped into one compact badge.
- **Two modes**: *All Keys*, or *Shortcuts Only* (combos that include ⌘, ⌃ or ⌥).
- **Word chips**: plain typing is merged into a single chip that grows as you type. Key repeat is collapsed for typed text and ignored for shortcuts.
- **Lone modifier taps** (for example pressing and releasing ⌘) are shown in All Keys mode.
- **Optional mouse click badges** for left, right and middle clicks, shown near the pointer.
- **Password safety**: the overlay is cleared and paused while macOS secure input is active (for example in password fields).
- **Position**: bottom center, bottom left, bottom right, top center, or follow the active screen. You can also pick which display to use.
- **Appearance**: fade delay (0.5–5 s), keycap size, text size, opacity, and a light, dark or accent color scheme, with a live preview in Settings.
- **Overlay behavior**: borderless, click-through, non-activating panel that floats above other windows and joins all Spaces. It is invisible when nothing was pressed recently, and shows at most eight chips at once.
- **Keyboard layouts**: uses the characters the system produces rather than raw key codes, so non-US layouts work.
- **Launch at login** through `SMAppService`.
- **Resilient**: re-enables the event tap if the system disables it.

## Screenshots

_Screenshots coming soon._

## Install

1. Download `KeyCapOverlay-macOS.zip` from the [latest release](https://github.com/turhe123/key-cap-overlay/releases/latest).
2. Unzip it and move `KeyCapOverlay.app` to `/Applications`.
3. The app is open source and not notarized, so clear the quarantine flag:

   ```bash
   xattr -cr /Applications/KeyCapOverlay.app
   ```

4. Right-click the app and choose **Open** the first time you launch it.

## Build from source

Requires macOS 14+ and Xcode with Swift 5.9 or later.

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project KeyCapOverlay.xcodeproj -scheme KeyCapOverlay -configuration Release -derivedDataPath ./build build
```

The app is produced at `build/Build/Products/Release/KeyCapOverlay.app`.

## Permissions

- **Accessibility** (the only permission the app asks for): needed so a listen-only event tap can see key presses and mouse clicks. The app prompts once, then checks every couple of seconds until access is granted. Until then the menu shows a "Grant Accessibility Access…" item. Keystrokes stay in memory, are only drawn on screen, and are never written to disk or sent over the network.

KeyCapOverlay does not request Screen Recording or Microphone access, because it does not capture the screen or audio. The overlay is a normal window, so screen recorders and streaming software can capture it like any other.

Launch at login uses the system login-item API; macOS may show its own notice when you enable it.

## Built with AI

KeyCapOverlay was written by [Claude Code](https://claude.com/claude-code) inside an automated pipeline, from a plain-English spec. No code, binaries or assets from any commercial app were used; it is a clean-room reimplementation of a feature set, not a copy.

What that means in practice:

- The full source is in this repo under the MIT license. Read it before you run it.
- No network calls, no analytics, no third-party dependencies. Only Apple frameworks.
- Ad-hoc signed and not notarized, which is why Gatekeeper warns on first launch.
- It has had less human review than a hand-written app. Bug reports and pull requests are welcome.

## Support ❤️

If KeyCapOverlay is useful to you, you can support its development:

[Support Or (Leo) Davidai ❤️ on Ko-fi](https://ko-fi.com/leodavidai)

The app also has a "Support / Donate ❤️" button in its menu and Settings window.

## License

MIT © Or Davidai Bachar

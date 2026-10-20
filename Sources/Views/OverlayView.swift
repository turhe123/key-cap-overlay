import SwiftUI

/// Renders the chip row; fully transparent when there are no chips.
struct OverlayView: View {
    @ObservedObject var model: OverlayModel
    @AppStorage(Prefs.keySize) private var keySize = 1.0
    @AppStorage(Prefs.textSize) private var textSize = 24.0
    @AppStorage(Prefs.colorScheme) private var scheme = ChipScheme.dark.rawValue
    @AppStorage(Prefs.opacity) private var opacity = 0.9
    @AppStorage(Prefs.position) private var position = OverlayPosition.bottomCenter.rawValue

    private var alignment: Alignment {
        switch OverlayPosition(rawValue: position) {
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        case .topCenter: .top
        default: .bottom
        }
    }

    var body: some View {
        HStack(spacing: 8 * keySize) {
            ForEach(model.chips) { chip in
                KeycapView(chip: chip, keySize: keySize, textSize: textSize,
                           scheme: ChipScheme(rawValue: scheme) ?? .dark)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .opacity(opacity)
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

/// A single rounded keycap.
struct KeycapView: View {
    let chip: Chip
    let keySize: Double
    let textSize: Double
    let scheme: ChipScheme

    private var colors: (bg: Color, fg: Color, edge: Color) {
        switch scheme {
        case .light: (Color(white: 0.97), .black, Color(white: 0.75))
        case .dark: (Color(white: 0.12), .white, Color(white: 0.35))
        case .accent: (.accentColor, .white, Color.white.opacity(0.4))
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(chip.text)
                .font(.system(size: textSize, weight: chip.isWord ? .medium : .semibold, design: .rounded))
                .lineLimit(1)
            if chip.count > 1 {
                Text("×\(chip.count)").font(.system(size: textSize * 0.55, weight: .bold)).opacity(0.7)
            }
        }
        .foregroundStyle(colors.fg)
        .padding(.horizontal, 14 * keySize)
        .padding(.vertical, 9 * keySize)
        .frame(minWidth: 48 * keySize, minHeight: 48 * keySize)
        .background(
            RoundedRectangle(cornerRadius: 11 * keySize, style: .continuous)
                .fill(colors.bg)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11 * keySize, style: .continuous)
                .strokeBorder(colors.edge, lineWidth: 1)
        )
    }
}

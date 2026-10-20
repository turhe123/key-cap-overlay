import SwiftUI

/// One keycap or word chip in the overlay.
struct Chip: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var isWord: Bool
    var count = 1
    var updated = Date()
}

/// Observable list of recent chips; expires them after the configured fade delay.
final class OverlayModel: ObservableObject {
    @Published private(set) var chips: [Chip] = []
    var onChange: (() -> Void)?
    private let maxChips = 8
    private let maxWordLength = 28
    private var timer: Timer?

    var lastIsActiveWord: Bool {
        guard let last = chips.last else { return false }
        return last.isWord && Date().timeIntervalSince(last.updated) < 1.2
    }

    func add(text: String, word: Bool) {
        mutate {
            if let i = chips.indices.last, chips[i].text == text, !chips[i].isWord {
                chips[i].count += 1
                chips[i].updated = Date()
            } else {
                chips.append(Chip(text: text, isWord: word))
            }
        }
    }

    /// Grows the current word chip, or starts a new one after a pause.
    func appendTyped(_ s: String) {
        if lastIsActiveWord, let i = chips.indices.last {
            mutate {
                chips[i].text = String((chips[i].text + s).suffix(maxWordLength))
                chips[i].updated = Date()
            }
        } else if s != " " {
            add(text: s, word: true)
        }
    }

    /// Key repeat: keep the last chip alive instead of adding duplicates.
    func touchLast() {
        guard let i = chips.indices.last else { return }
        chips[i].updated = Date()
    }

    func clear() {
        guard !chips.isEmpty else { return }
        mutate { chips.removeAll() }
    }

    private func mutate(_ change: () -> Void) {
        withAnimation(.easeOut(duration: 0.15)) {
            change()
            if chips.count > maxChips { chips.removeFirst(chips.count - maxChips) }
        }
        onChange?()
        scheduleExpiry()
    }

    private func scheduleExpiry() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            let delay = max(0.3, Prefs.defaults.double(forKey: Prefs.fadeDelay))
            let now = Date()
            if self.chips.contains(where: { now.timeIntervalSince($0.updated) > delay }) {
                withAnimation(.easeIn(duration: 0.35)) {
                    self.chips.removeAll { now.timeIntervalSince($0.updated) > delay }
                }
                self.onChange?()
            }
            if self.chips.isEmpty { t.invalidate(); self.timer = nil }
        }
    }
}

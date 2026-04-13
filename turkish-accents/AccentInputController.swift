import AppKit
import InputMethodKit

private let mappings: [String: String] = [
    "u": "ü", "U": "Ü",
    "o": "ö", "O": "Ö",
    "c": "ç", "C": "Ç",
    "s": "ş", "S": "Ş",
    "g": "ğ", "G": "Ğ",
    "i": "ı", "I": "İ",
]

/// Commits the base character on keyDown so typing has zero latency.  When the
/// system fires its first auto-repeat (~500ms, the same threshold macOS uses
/// for press-and-hold), replaces the already-inserted base with the accented
/// form in a single `insertText(_:replacementRange:)` call.
final class AccentInputController: IMKInputController {
    private var pendingKeyCode: UInt16?
    private var pendingAccent: String?
    private var pendingRange: NSRange?
    private var heldCommittedKeyCode: UInt16?

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown else { return false }

        if !event.modifierFlags.intersection([.command, .control, .option]).isEmpty {
            resetPending()
            heldCommittedKeyCode = nil
            return false
        }

        return event.isARepeat
            ? handleAutoRepeat(event)
            : handleFreshKeyDown(event)
    }

    private func handleFreshKeyDown(_ event: NSEvent) -> Bool {
        if heldCommittedKeyCode == event.keyCode {
            heldCommittedKeyCode = nil
        }
        resetPending()

        let typed = event.characters ?? ""
        guard let accent = mappings[typed], let client = self.client() else {
            return false
        }

        let selBefore = client.selectedRange()
        client.insertText(typed, replacementRange: NSRange(location: NSNotFound, length: 0))

        if selBefore.location != NSNotFound {
            pendingKeyCode = event.keyCode
            pendingAccent = accent
            pendingRange = NSRange(location: selBefore.location, length: typed.utf16.count)
        }
        return true
    }

    private func handleAutoRepeat(_ event: NSEvent) -> Bool {
        if event.keyCode == pendingKeyCode,
           let accent = pendingAccent,
           let range = pendingRange {
            if let client = self.client() {
                let sel = client.selectedRange()
                if sel.location == range.location + range.length, sel.length == 0 {
                    client.insertText(accent, replacementRange: range)
                }
            }
            heldCommittedKeyCode = event.keyCode
            resetPending()
            return true
        }

        if event.keyCode == heldCommittedKeyCode {
            return true
        }

        return false
    }

    private func resetPending() {
        pendingKeyCode = nil
        pendingAccent = nil
        pendingRange = nil
    }

    override func deactivateServer(_ sender: Any!) {
        resetPending()
        heldCommittedKeyCode = nil
    }
}

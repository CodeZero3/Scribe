import AppKit
import CoreGraphics

@MainActor
final class TextInserter {
    /// Insert text at cursor position in the active app via clipboard paste
    func insertText(_ text: String) async {
        let pasteboard = NSPasteboard.general

        // 1. Save current clipboard contents
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> (NSPasteboard.PasteboardType, Data)? in
            guard let firstType = item.types.first,
                  let data = item.data(forType: firstType) else { return nil }
            return (firstType, data)
        }

        // 2. Set our text on the clipboard
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 3. Small delay to ensure clipboard is set
        try? await Task.sleep(for: .milliseconds(50))

        // 4. Simulate Cmd+V to paste
        simulatePaste()

        // 5. Wait for paste to complete, then restore clipboard
        try? await Task.sleep(for: .milliseconds(300))

        // 6. Restore original clipboard
        pasteboard.clearContents()
        if let savedItems, !savedItems.isEmpty {
            for (type, data) in savedItems {
                pasteboard.setData(data, forType: type)
            }
        }
    }

    private func simulatePaste() {
        // Create Cmd+V key event
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code 0x09 = 'v' on macOS
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }
}

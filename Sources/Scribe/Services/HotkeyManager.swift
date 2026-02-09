import Foundation
@preconcurrency import HotKey

@Observable
@MainActor
final class HotkeyManager {
    private var dictationHotKey: HotKey?
    private var repasteHotKey: HotKey?

    var onToggleDictation: (() -> Void)?
    var onRepaste: (() -> Void)?

    func registerHotkeys() {
        // Ctrl+Shift+Space to toggle dictation
        dictationHotKey = HotKey(key: .space, modifiers: [.control, .shift])
        dictationHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.onToggleDictation?()
            }
        }

        // Ctrl+Shift+V to re-paste last dictation
        repasteHotKey = HotKey(key: .v, modifiers: [.control, .shift])
        repasteHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.onRepaste?()
            }
        }
    }

    func unregisterHotkeys() {
        dictationHotKey = nil
        repasteHotKey = nil
    }
}

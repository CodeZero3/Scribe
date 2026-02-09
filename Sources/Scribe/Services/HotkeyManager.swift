import AppKit
import CoreGraphics
import Foundation
@preconcurrency import HotKey

@Observable
@MainActor
final class HotkeyManager {
    private var repasteHotKey: HotKey?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onStartDictation: (() -> Void)?
    var onStopDictation: (() -> Void)?
    var onRepaste: (() -> Void)?

    /// Track physical key state for push-to-talk
    @ObservationIgnored
    private var controlDown = false
    @ObservationIgnored
    private var capsLockDown = false

    func registerHotkeys() {
        // Ctrl+Shift+V to re-paste last dictation
        repasteHotKey = HotKey(key: .v, modifiers: [.control, .shift])
        repasteHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in
                self?.onRepaste?()
            }
        }

        // Push-to-talk via CGEvent tap (Ctrl + CapsLock)
        setupPushToTalk()
    }

    func unregisterHotkeys() {
        repasteHotKey = nil
        teardownPushToTalk()
    }

    // MARK: - Push-to-talk via CGEvent tap

    private func setupPushToTalk() {
        // We need a pointer to self for the C callback
        let refcon = Unmanaged.passUnretained(self).toOpaque()

        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, _, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }

                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                let flags = event.flags

                // IMPORTANT: Do NOT use Task/@MainActor here — CGEvent tap
                // callbacks run outside Swift concurrency context, and the
                // runtime crashes trying to resolve the current executor.
                // Use GCD to hop to main thread safely instead.
                DispatchQueue.main.async {
                    let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                    MainActor.assumeIsolated {
                        manager.handleFlagsChanged(keyCode: keyCode, flags: flags)
                    }
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: refcon
        ) else {
            NSLog("[Scribe] Failed to create CGEvent tap — need Accessibility permission")
            return
        }

        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        NSLog("[Scribe] Push-to-talk event tap registered (Ctrl+CapsLock)")
    }

    private func teardownPushToTalk() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleFlagsChanged(keyCode: Int64, flags: CGEventFlags) {
        // Track Control key state
        let controlNow = flags.contains(.maskControl)

        // Track CapsLock physical key state via keycode 57
        // Each flagsChanged with keycode 57 = CapsLock was pressed or released
        // We toggle our tracking on each event with this keycode
        if keyCode == 57 {
            capsLockDown = !capsLockDown
        }

        let controlChanged = controlNow != controlDown
        controlDown = controlNow

        // Check push-to-talk state
        let shouldRecord = controlDown && capsLockDown

        if shouldRecord {
            onStartDictation?()
        } else if keyCode == 57 || controlChanged {
            // Only stop if a relevant key was released
            onStopDictation?()
        }
    }
}

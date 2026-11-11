import CoreGraphics
import Foundation
import os

enum Diag {
    static let subsystem = "co.409.uch"
    static let relay = Logger(subsystem: subsystem, category: "relay")
    static let caps = Logger(subsystem: subsystem, category: "caps")
    static let keys = Logger(subsystem: subsystem, category: "keys")

    /// Enabled with: defaults write io.yoonsungji.UniInputFix diagnosticsEnabled -bool YES
    static var probeEnabled: Bool { UserDefaults.standard.bool(forKey: "diagnosticsEnabled") }

    private static var probeTimer: DispatchSourceTimer?

    /// Samples Caps Lock flag sources every 5 ms for 1500 ms, logging only changes.
    static func startCapsProbe(reason: String) {
        guard probeEnabled else { return }
        probeTimer?.cancel()
        probeTimer = nil

        let start = DispatchTime.now()
        var last = CapsLockManager.flagSnapshot()
        caps.notice("PROBE start reason=\(reason, privacy: .public) \(last, privacy: .public)")

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .milliseconds(5))
        timer.setEventHandler {
            let elapsedMs = Int((DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000)
            if elapsedMs >= 1500 {
                timer.cancel()
                if probeTimer === timer { probeTimer = nil }
                caps.notice("PROBE end")
                return
            }
            let snapshot = CapsLockManager.flagSnapshot()
            if snapshot != last {
                last = snapshot
                caps.notice("PROBE +\(elapsedMs, privacy: .public)ms \(snapshot, privacy: .public)")
            }
        }
        probeTimer = timer
        timer.resume()
    }
}

/// Listen-only probe that logs ONLY Backspace (51) and Caps Lock (57) events. Never modifies events.
final class KeyProbe {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    fileprivate var lastCaps = false

    func start() {
        guard Diag.probeEnabled, tap == nil else { return }
        if AppPermissions.inputMonitoring != .granted {
            AppPermissions.requestInputMonitoring()
            Diag.keys.notice("KEY probe: input monitoring not granted yet")
        }
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passUnretained(event) }
            let probe = Unmanaged<KeyProbe>.fromOpaque(userInfo).takeUnretainedValue()
            probe.handle(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Diag.keys.notice("KEY probe: tap creation failed")
            return
        }
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
        tap = port
        source = runLoopSource
        Diag.keys.notice("KEY probe: started")
    }

    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
    }

    deinit { stop() }

    fileprivate func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
                Diag.keys.notice("KEY probe: tap re-enabled")
            }
        case .keyDown, .keyUp:
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            // Privacy: only Backspace (51) and Caps Lock (57) are ever logged.
            guard code == 51 || code == 57 else { return }
            let dir = type == .keyDown ? "down" : "up"
            let rep = event.getIntegerValueField(.keyboardEventAutorepeat)
            let kb = event.getIntegerValueField(.keyboardEventKeyboardType)
            let sid = event.getIntegerValueField(.eventSourceStateID)
            let pid = event.getIntegerValueField(.eventSourceUnixProcessID)
            let caps = event.flags.contains(.maskAlphaShift) ? 1 : 0
            Diag.keys.notice("KEY \(dir, privacy: .public) code=\(code, privacy: .public) repeat=\(rep, privacy: .public) kbType=\(kb, privacy: .public) stateID=\(sid, privacy: .public) srcPID=\(pid, privacy: .public) caps=\(caps, privacy: .public)")
        case .flagsChanged:
            let caps = event.flags.contains(.maskAlphaShift)
            guard caps != lastCaps else { return }
            lastCaps = caps
            let code = event.getIntegerValueField(.keyboardEventKeycode)
            Diag.keys.notice("KEY flags caps=\(caps ? 1 : 0, privacy: .public) code=\(code, privacy: .public)")
        default:
            return
        }
    }
}

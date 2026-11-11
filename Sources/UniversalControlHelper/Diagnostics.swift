import Foundation
import os

enum Diag {
    static let subsystem = "co.409.uch"
    static let relay = Logger(subsystem: subsystem, category: "relay")
    static let caps = Logger(subsystem: subsystem, category: "caps")

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

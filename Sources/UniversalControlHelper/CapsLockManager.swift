import AppKit
import Foundation
import IOKit
import IOKit.hid

public enum CapsLockManager {
    // Injectable hooks for deterministic unit testing
    internal static var isIOHIDCapsLockOnProvider: () -> Bool = {
        queryIOKitCapsLockState().isOn
    }

    internal static var isQuartzAlphaShiftOnProvider: () -> Bool = {
        checkQuartzAlphaShiftOn()
    }

    internal static var setIOHIDModifierLockStateProvider: (Bool) -> Bool = { on in
        setIOKitCapsLockState(on)
    }

    public static var isCapsLockOn: Bool {
        isIOHIDCapsLockOnProvider() || isQuartzAlphaShiftOnProvider()
    }

    private static func checkQuartzAlphaShiftOn() -> Bool {
        let hidState = CGEventSource.flagsState(.hidSystemState)
        let combinedState = CGEventSource.flagsState(.combinedSessionState)
        let nsState = NSEvent.modifierFlags
        return hidState.contains(.maskAlphaShift)
            || combinedState.contains(.maskAlphaShift)
            || nsState.contains(.capsLock)
    }

    private static func queryIOKitCapsLockState() -> (success: Bool, isOn: Bool) {
        guard let serviceDictionary = IOServiceMatching(kIOHIDSystemClass) else {
            return (false, false)
        }
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, serviceDictionary)
        guard ioService != MACH_PORT_NULL else { return (false, false) }
        defer { IOObjectRelease(ioService) }

        var ioConnection: io_connect_t = 0
        let result = IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnection)
        guard result == KERN_SUCCESS else { return (false, false) }
        defer { IOServiceClose(ioConnection) }

        var state = false
        let getResult = IOHIDGetModifierLockState(ioConnection, Int32(kIOHIDCapsLockState), &state)
        guard getResult == kIOReturnSuccess else { return (false, false) }
        return (true, state)
    }

    private static func setIOKitCapsLockState(_ on: Bool) -> Bool {
        guard let serviceDictionary = IOServiceMatching(kIOHIDSystemClass) else { return false }
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, serviceDictionary)
        guard ioService != MACH_PORT_NULL else { return false }
        defer { IOObjectRelease(ioService) }

        var ioConnection: io_connect_t = 0
        let result = IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnection)
        guard result == KERN_SUCCESS else { return false }
        defer { IOServiceClose(ioConnection) }

        let setResult = IOHIDSetModifierLockState(ioConnection, Int32(kIOHIDCapsLockState), on)
        return setResult == kIOReturnSuccess
    }

    /// Raw per-source Caps Lock state for diagnostics (does not use injectable providers).
    internal static func flagSnapshot() -> String {
        let io = queryIOKitCapsLockState().isOn
        let hid = CGEventSource.flagsState(.hidSystemState).contains(.maskAlphaShift)
        let ses = CGEventSource.flagsState(.combinedSessionState).contains(.maskAlphaShift)
        let ns = NSEvent.modifierFlags.contains(.capsLock)
        return "io=\(io ? 1 : 0) hid=\(hid ? 1 : 0) ses=\(ses ? 1 : 0) ns=\(ns ? 1 : 0)"
    }

    @discardableResult
    public static func disableCapsLock() -> Bool {
        Diag.caps.notice("disable before=\(flagSnapshot(), privacy: .public)")
        defer { Diag.caps.notice("disable after=\(flagSnapshot(), privacy: .public)") }
        _ = setIOHIDModifierLockStateProvider(false)
        if isQuartzAlphaShiftOnProvider() {
            Diag.caps.notice("disable pulse true->false ran")
            // Pulse toggle true then false to force IOHIDSystem to notify WindowServer and clear maskAlphaShift
            _ = setIOHIDModifierLockStateProvider(true)
            _ = setIOHIDModifierLockStateProvider(false)
        }
        return !isCapsLockOn
    }

    private static var pendingSuppressionWorkItem: DispatchWorkItem?

    /// Suppresses unintended Caps Lock on Target Mac by immediately turning it off
    /// and running a single cancellable follow-up check at 50ms to catch delayed Universal Control events.
    public static func suppressCapsLock(followUpDelay: TimeInterval = 0.050) {
        cancelSuppression()

        if isCapsLockOn {
            _ = disableCapsLock()
        }

        let workItem = DispatchWorkItem {
            if isCapsLockOn {
                Diag.caps.notice("suppress follow-up found Caps Lock on")
                _ = disableCapsLock()
            }
        }
        pendingSuppressionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + followUpDelay, execute: workItem)
    }

    public static func cancelSuppression() {
        pendingSuppressionWorkItem?.cancel()
        pendingSuppressionWorkItem = nil
    }

    internal static func resetProviders() {
        cancelSuppression()
        isIOHIDCapsLockOnProvider = { queryIOKitCapsLockState().isOn }
        isQuartzAlphaShiftOnProvider = { checkQuartzAlphaShiftOn() }
        setIOHIDModifierLockStateProvider = { on in setIOKitCapsLockState(on) }
    }
}

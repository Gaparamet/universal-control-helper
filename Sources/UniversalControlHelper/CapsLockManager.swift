import Foundation
import IOKit
import IOKit.hid

public enum CapsLockManager {
    public static var isCapsLockOn: Bool {
        guard let serviceDictionary = IOServiceMatching(kIOHIDSystemClass) else { return false }
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, serviceDictionary)
        if ioService == MACH_PORT_NULL { return false }
        var ioConnection: io_connect_t = 0
        let result = IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnection)
        IOObjectRelease(ioService)
        if result == KERN_SUCCESS {
            var state = false
            IOHIDGetModifierLockState(ioConnection, Int32(kIOHIDCapsLockState), &state)
            IOServiceClose(ioConnection)
            return state
        }
        return false
    }

    public static func disableCapsLock() {
        guard let serviceDictionary = IOServiceMatching(kIOHIDSystemClass) else { return }
        let ioService = IOServiceGetMatchingService(kIOMainPortDefault, serviceDictionary)
        if ioService == MACH_PORT_NULL { return }
        var ioConnection: io_connect_t = 0
        let result = IOServiceOpen(ioService, mach_task_self_, UInt32(kIOHIDParamConnectType), &ioConnection)
        IOObjectRelease(ioService)
        if result == KERN_SUCCESS {
            IOHIDSetModifierLockState(ioConnection, Int32(kIOHIDCapsLockState), false)
            IOServiceClose(ioConnection)
        }
    }

    /// Suppresses Caps Lock on Target Mac by immediately turning it off and running staggered
    /// checks over the subsequent window to catch any delayed Universal Control HID events.
    public static func suppressCapsLock() {
        disableCapsLock()
        let delays: [Double] = [0.02, 0.05, 0.10, 0.18, 0.30, 0.50, 0.75]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isCapsLockOn {
                    disableCapsLock()
                }
            }
        }
    }
}

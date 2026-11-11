import Carbon
import os
import IOKit.hid
import UniversalControlCore

final class PhysicalCapsLockMonitor {
    var onCapsLockPressed: (() -> Void)?

    private var manager: IOHIDManager?

    @discardableResult
    func start() -> Bool {
        guard manager == nil else { return true }
        if AppPermissions.inputMonitoring != .granted {
            AppPermissions.requestInputMonitoring()
        }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = manager
        let matches: [[String: Int]] = [[
            kIOHIDDeviceUsagePageKey as String: Int(kHIDPage_GenericDesktop),
            kIOHIDDeviceUsageKey as String: Int(kHIDUsage_GD_Keyboard),
        ]]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matches as CFArray)
        IOHIDManagerRegisterInputValueCallback(
            manager,
            { context, _, _, value in
                guard let context else { return }
                let monitor = Unmanaged<PhysicalCapsLockMonitor>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                monitor.handle(value)
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
        IOHIDManagerScheduleWithRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )

        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            IOHIDManagerUnscheduleFromRunLoop(
                manager,
                CFRunLoopGetMain(),
                CFRunLoopMode.commonModes.rawValue
            )
            self.manager = nil
            return false
        }
        return true
    }

    func stop() {
        guard let manager else { return }
        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.manager = nil
    }

    private func handle(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        guard isPhysicalDevice(IOHIDElementGetDevice(element)) else { return }
        guard IOHIDElementGetUsagePage(element) == UInt32(kHIDPage_KeyboardOrKeypad),
              IOHIDElementGetUsage(element) == UInt32(kHIDUsage_KeyboardCapsLock) else {
            return
        }
        switch IOHIDValueGetIntegerValue(value) {
        case 1:
            Diag.relay.notice("SRC capsDown current=\(InputSourceController.currentState?.rawValue ?? "nil", privacy: .public) caps=\(CapsLockManager.flagSnapshot(), privacy: .public)")
            onCapsLockPressed?()
            SourceCapsLockNeutralizer.schedule(reason: "down")
        case 0:
            Diag.relay.notice("SRC capsUp caps=\(CapsLockManager.flagSnapshot(), privacy: .public)")
            SourceCapsLockNeutralizer.schedule(reason: "up")
        default:
            return
        }
    }

    private func isPhysicalDevice(_ device: IOHIDDevice?) -> Bool {
        guard let device else { return false }
        let transport = property(kIOHIDTransportKey as CFString, device: device).lowercased()
        let product = property(kIOHIDProductKey as CFString, device: device).lowercased()
        return !transport.contains("virtual")
            && !product.contains("virtual")
            && !product.contains("universal control")
    }

    private func property(_ key: CFString, device: IOHIDDevice) -> String {
        IOHIDDeviceGetProperty(device, key) as? String ?? ""
    }

    deinit {
        stop()
    }
}

/// Experiment: while Universal Control forwards the Source keyboard, a physical Caps Lock press
/// toggles the real Caps Lock on the Source and UC re-applies it on the Target. Clear it on the
/// Source right after each press/release. Runs on the main thread.
enum SourceCapsLockNeutralizer {
    static var isEnabled: () -> Bool = {
        UserDefaults.standard.object(forKey: "sourceClearsCapsLock") as? Bool ?? true
    }
    static var delays: [TimeInterval] = [0, 0.03, 0.12]

    private static var pending: [DispatchWorkItem] = []

    static func schedule(reason: String) {
        guard isEnabled() else { return }
        cancel()
        for delay in delays {
            if delay <= 0 {
                run(reason: reason, delay: delay)
            } else {
                let item = DispatchWorkItem { run(reason: reason, delay: delay) }
                pending.append(item)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
            }
        }
    }

    static func cancel() {
        pending.forEach { $0.cancel() }
        pending.removeAll()
    }

    internal static func reset() {
        cancel()
        isEnabled = {
            UserDefaults.standard.object(forKey: "sourceClearsCapsLock") as? Bool ?? true
        }
        delays = [0, 0.03, 0.12]
    }

    private static func run(reason: String, delay: TimeInterval) {
        guard CapsLockManager.isCapsLockOn else { return }
        let ms = Int((delay * 1000).rounded())
        Diag.caps.notice("SRC neutralize reason=\(reason, privacy: .public) +\(ms, privacy: .public)ms")
        _ = CapsLockManager.disableCapsLock()
    }
}

final class InputSourceRelay {
    var send: ((InputSourceState) -> Void)?

    private var monitor: InputSourceMonitor?

    @discardableResult
    func start() -> Bool {
        guard monitor == nil else { return true }
        let monitor = InputSourceMonitor()
        monitor.stateDidChange = { [weak self] state in self?.send?(state) }
        monitor.start()
        self.monitor = monitor
        return true
    }

    func stop() {
        monitor?.stop()
        monitor = nil
    }

    func synchronizeCurrentState() {
        guard let state = InputSourceController.currentState else { return }
        send?(state)
    }
}

final class InputSourceMonitor {
    var stateDidChange: ((InputSourceState) -> Void)?

    private var isStarted = false
    private var lastState: InputSourceState?

    func start() {
        guard !isStarted else { return }
        isStarted = true
        lastState = InputSourceController.currentState
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            inputSourceChangedCallback,
            kTISNotifySelectedKeyboardInputSourceChanged,
            nil,
            .deliverImmediately
        )
    }

    func stop() {
        guard isStarted else { return }
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(kTISNotifySelectedKeyboardInputSourceChanged),
            nil
        )
        isStarted = false
    }

    fileprivate func inputSourceDidChange() {
        guard let state = InputSourceController.currentState, state != lastState else { return }
        Diag.relay.notice("SRC inputSourceChanged \(self.lastState?.rawValue ?? "nil", privacy: .public)->\(state.rawValue, privacy: .public)")
        lastState = state
        stateDidChange?(state)
    }

    deinit {
        stop()
    }
}

private func inputSourceChangedCallback(
    _: CFNotificationCenter?,
    observer: UnsafeMutableRawPointer?,
    _: CFNotificationName?,
    _: UnsafeRawPointer?,
    _: CFDictionary?
) {
    guard let observer else { return }
    let monitor = Unmanaged<InputSourceMonitor>.fromOpaque(observer).takeUnretainedValue()
    monitor.inputSourceDidChange()
}

enum TargetInputInjector {
    static var shouldPreventCapsLock: () -> Bool = { true }

    // Testable injection hooks
    internal static var uptimeProvider: () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    internal static var currentSourceProvider: () -> InputSourceState? = { InputSourceController.currentState }
    internal static var sourceToggler: () -> Void = { InputSourceController.toggleInputSource() }
    internal static var sourceSelector: (InputSourceState) -> Void = { InputSourceController.select($0) }
    internal static var suppressionHandler: () -> Void = { CapsLockManager.suppressCapsLock() }
    internal static var isCapsLockOnProvider: () -> Bool = { CapsLockManager.isCapsLockOn }

    private static var lastSwitchTime: TimeInterval = 0
    private static var lastTargetState: InputSourceState?

    private static func tgtState(_ state: InputSourceState?) -> String {
        state?.rawValue ?? "nil"
    }

    static func handle(_ message: RelayMessage) {
        let now = uptimeProvider()
        switch message.kind {
        case .toggleInputSource:
            Diag.startCapsProbe(reason: "toggleInputSource")
            Diag.relay.notice("TGT recv kind=toggleInputSource desired=- current=\(tgtState(currentSourceProvider()), privacy: .public) caps=\(CapsLockManager.flagSnapshot(), privacy: .public)")
            // Deduplicate rapid successive toggle requests within 100ms
            if now - lastSwitchTime < 0.100 {
                Diag.relay.notice("TGT drop reason=toggle-dedupe-100ms")
                return
            }
            lastSwitchTime = now
            sourceToggler()
            lastTargetState = currentSourceProvider()
            Diag.relay.notice("TGT after current=\(tgtState(lastTargetState), privacy: .public)")
            if shouldPreventCapsLock() {
                suppressionHandler()
            }
        case .setInputSource:
            guard let desired = message.inputSource else { return }
            let current = currentSourceProvider()
            Diag.startCapsProbe(reason: "setInputSource")
            Diag.relay.notice("TGT recv kind=setInputSource desired=\(desired.rawValue, privacy: .public) current=\(tgtState(current), privacy: .public) caps=\(CapsLockManager.flagSnapshot(), privacy: .public)")
            if current == desired {
                // Already in desired state; clean up unintended Caps Lock if active
                if shouldPreventCapsLock() && isCapsLockOnProvider() {
                    suppressionHandler()
                }
                Diag.relay.notice("TGT drop reason=already-desired")
                return
            }
            // Deduplicate if a switch to this state just occurred within 150ms
            if lastTargetState == desired && now - lastSwitchTime < 0.150 {
                Diag.relay.notice("TGT drop reason=set-dedupe-150ms")
                return
            }
            lastSwitchTime = now
            lastTargetState = desired
            sourceSelector(desired)
            Diag.relay.notice("TGT after current=\(tgtState(currentSourceProvider()), privacy: .public)")
            if shouldPreventCapsLock() {
                suppressionHandler()
            }
        case .hello, .helloAck:
            break
        }
    }

    internal static func resetState() {
        lastSwitchTime = 0
        lastTargetState = nil
        uptimeProvider = { ProcessInfo.processInfo.systemUptime }
        currentSourceProvider = { InputSourceController.currentState }
        sourceToggler = { InputSourceController.toggleInputSource() }
        sourceSelector = { InputSourceController.select($0) }
        suppressionHandler = { CapsLockManager.suppressCapsLock() }
        isCapsLockOnProvider = { CapsLockManager.isCapsLockOn }
    }
}

final class TargetCapsLockGuard {
    private var isStarted = false
    var isEnabled: () -> Bool = { true }

    // Testable injection hooks
    internal var isCapsLockOnProvider: () -> Bool = { CapsLockManager.isCapsLockOn }
    internal var suppressionHandler: () -> Void = { CapsLockManager.suppressCapsLock() }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            targetInputSourceChangedCallback,
            kTISNotifySelectedKeyboardInputSourceChanged,
            nil,
            .deliverImmediately
        )
    }

    func stop() {
        guard isStarted else { return }
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDistributedCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(kTISNotifySelectedKeyboardInputSourceChanged),
            nil
        )
        isStarted = false
    }

    fileprivate func inputSourceDidChange() {
        let enabled = isEnabled()
        guard enabled else {
            Diag.relay.notice("TGT guard inputSourceChanged capsOn=- enabled=false")
            return
        }
        // Suppress only if Caps Lock or AlphaShift is actually detected active
        let capsOn = isCapsLockOnProvider()
        Diag.relay.notice("TGT guard inputSourceChanged capsOn=\(capsOn, privacy: .public) enabled=\(enabled, privacy: .public)")
        if capsOn {
            suppressionHandler()
        }
    }

    internal func inputSourceDidChangeForTesting() {
        inputSourceDidChange()
    }

    deinit {
        stop()
    }
}

private func targetInputSourceChangedCallback(
    _: CFNotificationCenter?,
    observer: UnsafeMutableRawPointer?,
    _: CFNotificationName?,
    _: UnsafeRawPointer?,
    _: CFDictionary?
) {
    guard let observer else { return }
    let guardInstance = Unmanaged<TargetCapsLockGuard>.fromOpaque(observer).takeUnretainedValue()
    guardInstance.inputSourceDidChange()
}

enum InputSourceController {
    private static var cachedSources: [TISInputSource]?
    private static var isEnabledSourcesObserverRegistered = false

    static var currentState: InputSourceState? {
        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }
        return InputSourceSelection.state(
            id: identifier(of: current),
            name: localizedName(of: current)
        )
    }

    static func select(_ state: InputSourceState) {
        if currentState == state { return }
        guard let target = inputSource(for: state) else { return }
        TISSelectInputSource(target)
    }

    static func toggleInputSource() {
        guard let current = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return }
        let candidates = inputSources()
        let descriptors = candidates.map(descriptor)
        guard let targetID = InputSourceSelection.targetID(
            currentID: identifier(of: current),
            candidates: descriptors
        ), let target = candidates.first(where: { identifier(of: $0) == targetID }) else {
            return
        }
        TISSelectInputSource(target)
    }

    static func toggleKoreanAndABC() {
        toggleInputSource()
    }

    private static func inputSource(for state: InputSourceState) -> TISInputSource? {
        let candidates = inputSources()
        let descriptors = candidates.map(descriptor)
        guard let targetID = InputSourceSelection.targetID(for: state, candidates: descriptors) else {
            return nil
        }
        return candidates.first { identifier(of: $0) == targetID }
    }

    public static func invalidateCache() {
        cachedSources = nil
    }

    private static func registerEnabledSourcesObserverIfNeeded() {
        guard !isEnabledSourcesObserverRegistered else { return }
        isEnabledSourcesObserverRegistered = true
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDistributedCenter(),
            nil,
            { _, _, _, _, _ in
                InputSourceController.invalidateCache()
            },
            kTISNotifyEnabledKeyboardInputSourcesChanged,
            nil,
            .deliverImmediately
        )
    }

    private static func inputSources() -> [TISInputSource] {
        registerEnabledSourcesObserverIfNeeded()
        if let cached = cachedSources {
            return cached
        }
        guard let unmanaged = TISCreateInputSourceList(nil, false) else { return [] }
        let list = unmanaged.takeRetainedValue() as! [TISInputSource]
        cachedSources = list
        return list
    }

    private static func descriptor(_ source: TISInputSource) -> InputSourceDescriptor {
        InputSourceDescriptor(id: identifier(of: source), name: localizedName(of: source))
    }

    private static func identifier(of source: TISInputSource) -> String {
        stringProperty(kTISPropertyInputSourceID, of: source)
    }

    private static func localizedName(of source: TISInputSource) -> String {
        stringProperty(kTISPropertyLocalizedName, of: source)
    }

    private static func stringProperty(_ key: CFString, of source: TISInputSource) -> String {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return "" }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }
}

import Foundation
import Testing
@testable import UniversalControlHelper

extension HelperSerialTests {
    @Suite final class SourceCapsLockNeutralizerTests {
        init() {
            CapsLockManager.resetProviders()
            SourceCapsLockNeutralizer.reset()
        }

        deinit {
            CapsLockManager.resetProviders()
            SourceCapsLockNeutralizer.reset()
        }

        @Test func enabledAndCapsOnDisablesImmediately() {
            var states: [Bool] = []
            SourceCapsLockNeutralizer.isEnabled = { true }
            SourceCapsLockNeutralizer.delays = [0]
            CapsLockManager.isIOHIDCapsLockOnProvider = { true }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }
            CapsLockManager.setIOHIDModifierLockStateProvider = { on in states.append(on); return true }

            SourceCapsLockNeutralizer.schedule(reason: "down")

            #expect(states.first == false)
        }

        @Test func disabledNeverCallsProvider() {
            var calls = 0
            SourceCapsLockNeutralizer.isEnabled = { false }
            SourceCapsLockNeutralizer.delays = [0]
            CapsLockManager.isIOHIDCapsLockOnProvider = { true }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { true }
            CapsLockManager.setIOHIDModifierLockStateProvider = { _ in calls += 1; return true }

            SourceCapsLockNeutralizer.schedule(reason: "down")

            #expect(calls == 0)
        }

        @Test func capsOffNeverCallsProvider() {
            var calls = 0
            SourceCapsLockNeutralizer.isEnabled = { true }
            SourceCapsLockNeutralizer.delays = [0]
            CapsLockManager.isIOHIDCapsLockOnProvider = { false }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }
            CapsLockManager.setIOHIDModifierLockStateProvider = { _ in calls += 1; return true }

            SourceCapsLockNeutralizer.schedule(reason: "up")

            #expect(calls == 0)
        }

        @MainActor
        @Test func delayedPassDisablesLateCapsOn() async throws {
            var capsOn = false
            var states: [Bool] = []
            SourceCapsLockNeutralizer.isEnabled = { true }
            SourceCapsLockNeutralizer.delays = [0, 0.02]
            CapsLockManager.isIOHIDCapsLockOnProvider = { capsOn }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }
            CapsLockManager.setIOHIDModifierLockStateProvider = { on in
                states.append(on)
                if !on { capsOn = false }
                return true
            }

            SourceCapsLockNeutralizer.schedule(reason: "down")
            #expect(states.isEmpty)
            capsOn = true
            try await Task.sleep(nanoseconds: 200_000_000)

            #expect(states.first == false)
            #expect(!capsOn)
        }
    }
}

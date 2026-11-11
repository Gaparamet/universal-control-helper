import Foundation
import Testing
@testable import UniversalControlHelper

extension HelperSerialTests {
    @Suite final class CapsLockManagerTests {
        init() {
            CapsLockManager.resetProviders()
        }

        deinit {
            CapsLockManager.resetProviders()
        }

        @Test func isCapsLockOnWhenIOHIDIsTrue() {
            CapsLockManager.isIOHIDCapsLockOnProvider = { true }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }

            #expect(CapsLockManager.isCapsLockOn)
        }

        @Test func isCapsLockOnWhenQuartzIsDesyncedAndIOHIDIsFalse() {
            // Desynchronization scenario: IOHID thinks it's false, but Quartz has maskAlphaShift
            CapsLockManager.isIOHIDCapsLockOnProvider = { false }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { true }

            #expect(CapsLockManager.isCapsLockOn)
        }

        @Test func isCapsLockOffWhenBothAreFalse() {
            CapsLockManager.isIOHIDCapsLockOnProvider = { false }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }

            #expect(!CapsLockManager.isCapsLockOn)
        }

        @Test func disableCapsLockPulsesWhenQuartzLingers() {
            var recordedStates: [Bool] = []
            var quartzState = true

            CapsLockManager.setIOHIDModifierLockStateProvider = { on in
                recordedStates.append(on)
                if !on && recordedStates.count >= 3 {
                    quartzState = false
                }
                return true
            }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { quartzState }
            CapsLockManager.isIOHIDCapsLockOnProvider = { false }

            let result = CapsLockManager.disableCapsLock()

            // Should have called: false, then pulse (true, false)
            #expect(recordedStates == [false, true, false])
            #expect(result)
            #expect(!CapsLockManager.isCapsLockOn)
        }

        // The follow-up check is scheduled with DispatchQueue.main.asyncAfter, so these
        // tests run on the main actor and suspend in Task.sleep to let the main queue drain.
        @MainActor
        @Test func suppressCapsLockExecutesImmediateDisablingWhenActive() async throws {
            var disabledCount = 0
            var currentState = true

            CapsLockManager.isIOHIDCapsLockOnProvider = { currentState }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }
            CapsLockManager.setIOHIDModifierLockStateProvider = { on in
                if !on {
                    disabledCount += 1
                    currentState = false
                }
                return true
            }

            CapsLockManager.suppressCapsLock(followUpDelay: 0.02)
            #expect(disabledCount == 1)

            try await Task.sleep(nanoseconds: 100_000_000)
            // Follow up ran, but state was already false so disable wasn't called a second time
            #expect(disabledCount == 1)
        }

        @MainActor
        @Test func cancelSuppressionPreventsFollowUp() async throws {
            var followUpRan = false
            var currentState = false

            CapsLockManager.isIOHIDCapsLockOnProvider = { currentState }
            CapsLockManager.isQuartzAlphaShiftOnProvider = { false }
            CapsLockManager.setIOHIDModifierLockStateProvider = { on in
                if !on { followUpRan = true }
                return true
            }

            CapsLockManager.suppressCapsLock(followUpDelay: 0.03)
            // Immediately cancel
            CapsLockManager.cancelSuppression()

            // Simulate delayed state turn-on that would have triggered follow-up if not cancelled
            currentState = true

            try await Task.sleep(nanoseconds: 100_000_000)
            #expect(!followUpRan)
        }
    }
}

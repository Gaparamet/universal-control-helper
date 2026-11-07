import XCTest
@testable import UniversalControlHelper

final class CapsLockManagerTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        CapsLockManager.resetProviders()
    }

    func testIsCapsLockOnWhenIOHIDIsTrue() {
        CapsLockManager.isIOHIDCapsLockOnProvider = { true }
        CapsLockManager.isQuartzAlphaShiftOnProvider = { false }

        XCTAssertTrue(CapsLockManager.isCapsLockOn)
    }

    func testIsCapsLockOnWhenQuartzIsDesyncedAndIOHIDIsFalse() {
        // Desynchronization scenario: IOHID thinks it's false, but Quartz has maskAlphaShift
        CapsLockManager.isIOHIDCapsLockOnProvider = { false }
        CapsLockManager.isQuartzAlphaShiftOnProvider = { true }

        XCTAssertTrue(CapsLockManager.isCapsLockOn)
    }

    func testIsCapsLockOffWhenBothAreFalse() {
        CapsLockManager.isIOHIDCapsLockOnProvider = { false }
        CapsLockManager.isQuartzAlphaShiftOnProvider = { false }

        XCTAssertFalse(CapsLockManager.isCapsLockOn)
    }

    func testDisableCapsLockPulsesWhenQuartzLingers() {
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
        XCTAssertEqual(recordedStates, [false, true, false])
        XCTAssertTrue(result)
        XCTAssertFalse(CapsLockManager.isCapsLockOn)
    }

    func testSuppressCapsLockExecutesImmediateDisablingWhenActive() {
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
        XCTAssertEqual(disabledCount, 1)

        let expectation = expectation(description: "Follow-up check completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            // Follow up ran, but state was already false so disable wasn't called a second time
            XCTAssertEqual(disabledCount, 1)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testCancelSuppressionPreventsFollowUp() {
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

        let expectation = expectation(description: "Cancelled follow-up did not run")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            XCTAssertFalse(followUpRan)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

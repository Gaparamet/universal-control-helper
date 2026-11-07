import XCTest
@testable import UniversalControlHelper

final class TargetCapsLockGuardTests: XCTestCase {
    func testGuardDisabledDoesNotSuppress() {
        let guardInstance = TargetCapsLockGuard()
        var suppressionCalled = false

        guardInstance.isEnabled = { false }
        guardInstance.isCapsLockOnProvider = { true }
        guardInstance.suppressionHandler = { suppressionCalled = true }

        // Directly invoke inputSourceDidChange
        guardInstance.inputSourceDidChangeForTesting()

        XCTAssertFalse(suppressionCalled)
    }

    func testGuardEnabledOnlySuppressesWhenCapsLockIsOn() {
        let guardInstance = TargetCapsLockGuard()
        var suppressionCount = 0

        guardInstance.isEnabled = { true }
        guardInstance.isCapsLockOnProvider = { false }
        guardInstance.suppressionHandler = { suppressionCount += 1 }

        // When Caps Lock is OFF, should NOT call suppression
        guardInstance.inputSourceDidChangeForTesting()
        XCTAssertEqual(suppressionCount, 0)

        // When Caps Lock is ON, SHOULD call suppression
        guardInstance.isCapsLockOnProvider = { true }
        guardInstance.inputSourceDidChangeForTesting()
        XCTAssertEqual(suppressionCount, 1)
    }
}

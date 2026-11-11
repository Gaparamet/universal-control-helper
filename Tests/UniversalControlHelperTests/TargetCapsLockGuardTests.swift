import Testing
@testable import UniversalControlHelper

extension HelperSerialTests {
    @Suite struct TargetCapsLockGuardTests {
        @Test func guardDisabledDoesNotSuppress() {
            let guardInstance = TargetCapsLockGuard()
            var suppressionCalled = false

            guardInstance.isEnabled = { false }
            guardInstance.isCapsLockOnProvider = { true }
            guardInstance.suppressionHandler = { suppressionCalled = true }

            // Directly invoke inputSourceDidChange
            guardInstance.inputSourceDidChangeForTesting()

            #expect(!suppressionCalled)
        }

        @Test func guardEnabledOnlySuppressesWhenCapsLockIsOn() {
            let guardInstance = TargetCapsLockGuard()
            var suppressionCount = 0

            guardInstance.isEnabled = { true }
            guardInstance.isCapsLockOnProvider = { false }
            guardInstance.suppressionHandler = { suppressionCount += 1 }

            // When Caps Lock is OFF, should NOT call suppression
            guardInstance.inputSourceDidChangeForTesting()
            #expect(suppressionCount == 0)

            // When Caps Lock is ON, SHOULD call suppression
            guardInstance.isCapsLockOnProvider = { true }
            guardInstance.inputSourceDidChangeForTesting()
            #expect(suppressionCount == 1)
        }
    }
}

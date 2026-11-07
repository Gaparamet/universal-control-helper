import XCTest
import UniversalControlCore
@testable import UniversalControlHelper

final class TargetInputInjectorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        TargetInputInjector.resetState()
    }

    override func tearDown() {
        super.tearDown()
        TargetInputInjector.resetState()
    }

    func testGuardDisabledDoesNotSuppressCapsLock() {
        var suppressionCalled = false
        var toggled = false

        TargetInputInjector.shouldPreventCapsLock = { false }
        TargetInputInjector.sourceToggler = { toggled = true }
        TargetInputInjector.suppressionHandler = { suppressionCalled = true }

        let message = RelayMessage.toggleInputSource(token: "test")
        TargetInputInjector.handle(message)

        XCTAssertTrue(toggled)
        XCTAssertFalse(suppressionCalled)
    }

    func testGuardEnabledSuppressesCapsLockOnToggle() {
        var suppressionCalled = false
        var toggled = false

        TargetInputInjector.shouldPreventCapsLock = { true }
        TargetInputInjector.sourceToggler = { toggled = true }
        TargetInputInjector.suppressionHandler = { suppressionCalled = true }

        let message = RelayMessage.toggleInputSource(token: "test")
        TargetInputInjector.handle(message)

        XCTAssertTrue(toggled)
        XCTAssertTrue(suppressionCalled)
    }

    func testRapidToggleIsDeduplicatedWithinWindow() {
        var toggleCount = 0
        var virtualTime: TimeInterval = 100.0

        TargetInputInjector.uptimeProvider = { virtualTime }
        TargetInputInjector.sourceToggler = { toggleCount += 1 }

        let message = RelayMessage.toggleInputSource(token: "test")

        TargetInputInjector.handle(message)
        XCTAssertEqual(toggleCount, 1)

        // Rapid duplicate 20ms later
        virtualTime = 100.02
        TargetInputInjector.handle(message)
        XCTAssertEqual(toggleCount, 1)

        // Subsequent toggle after debounce window (110ms later)
        virtualTime = 100.12
        TargetInputInjector.handle(message)
        XCTAssertEqual(toggleCount, 2)
    }

    func testSetInputSourceSkipsWhenAlreadyInDesiredState() {
        var selectedCount = 0
        var suppressionCalled = false

        TargetInputInjector.currentSourceProvider = { .thai }
        TargetInputInjector.sourceSelector = { _ in selectedCount += 1 }
        TargetInputInjector.suppressionHandler = { suppressionCalled = true }
        TargetInputInjector.isCapsLockOnProvider = { false }

        let message = RelayMessage.setInputSource(.thai, token: "test")
        TargetInputInjector.handle(message)

        XCTAssertEqual(selectedCount, 0)
        XCTAssertFalse(suppressionCalled)
    }

    func testSetInputSourceCleansUpCapsLockWhenAlreadyInDesiredStateIfCapsOn() {
        var selectedCount = 0
        var suppressionCalled = false

        TargetInputInjector.currentSourceProvider = { .thai }
        TargetInputInjector.sourceSelector = { _ in selectedCount += 1 }
        TargetInputInjector.suppressionHandler = { suppressionCalled = true }
        TargetInputInjector.isCapsLockOnProvider = { true }

        let message = RelayMessage.setInputSource(.thai, token: "test")
        TargetInputInjector.handle(message)

        XCTAssertEqual(selectedCount, 0)
        XCTAssertTrue(suppressionCalled)
    }

    func testSetInputSourceDeduplicatesRapidSwitch() {
        var selectedSources: [InputSourceState] = []
        var virtualTime: TimeInterval = 100.0
        var currentSource: InputSourceState = .abc

        TargetInputInjector.uptimeProvider = { virtualTime }
        TargetInputInjector.currentSourceProvider = { currentSource }
        TargetInputInjector.sourceSelector = { state in
            selectedSources.append(state)
            currentSource = state
        }

        let message = RelayMessage.setInputSource(.thai, token: "test")

        // First switch to Thai
        TargetInputInjector.handle(message)
        XCTAssertEqual(selectedSources, [.thai])

        // Duplicate incoming message 20ms later
        virtualTime = 100.02
        TargetInputInjector.handle(message)
        XCTAssertEqual(selectedSources, [.thai])
    }
}

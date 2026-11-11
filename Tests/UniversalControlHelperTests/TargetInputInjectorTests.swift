import Foundation
import Testing
import UniversalControlCore
@testable import UniversalControlHelper

extension HelperSerialTests {
    @Suite final class TargetInputInjectorTests {
        init() {
            TargetInputInjector.resetState()
        }

        deinit {
            TargetInputInjector.resetState()
        }

        @Test func guardDisabledDoesNotSuppressCapsLock() {
            var suppressionCalled = false
            var toggled = false

            TargetInputInjector.shouldPreventCapsLock = { false }
            TargetInputInjector.sourceToggler = { toggled = true }
            TargetInputInjector.suppressionHandler = { suppressionCalled = true }

            let message = RelayMessage.toggleInputSource(token: "test")
            TargetInputInjector.handle(message)

            #expect(toggled)
            #expect(!suppressionCalled)
        }

        @Test func guardEnabledSuppressesCapsLockOnToggle() {
            var suppressionCalled = false
            var toggled = false

            TargetInputInjector.shouldPreventCapsLock = { true }
            TargetInputInjector.sourceToggler = { toggled = true }
            TargetInputInjector.suppressionHandler = { suppressionCalled = true }

            let message = RelayMessage.toggleInputSource(token: "test")
            TargetInputInjector.handle(message)

            #expect(toggled)
            #expect(suppressionCalled)
        }

        @Test func rapidToggleIsDeduplicatedWithinWindow() {
            var toggleCount = 0
            var virtualTime: TimeInterval = 100.0

            TargetInputInjector.uptimeProvider = { virtualTime }
            TargetInputInjector.sourceToggler = { toggleCount += 1 }

            let message = RelayMessage.toggleInputSource(token: "test")

            TargetInputInjector.handle(message)
            #expect(toggleCount == 1)

            // Rapid duplicate 20ms later
            virtualTime = 100.02
            TargetInputInjector.handle(message)
            #expect(toggleCount == 1)

            // Subsequent toggle after debounce window (110ms later)
            virtualTime = 100.12
            TargetInputInjector.handle(message)
            #expect(toggleCount == 2)
        }

        @Test func setInputSourceSkipsWhenAlreadyInDesiredState() {
            var selectedCount = 0
            var suppressionCalled = false

            TargetInputInjector.currentSourceProvider = { .thai }
            TargetInputInjector.sourceSelector = { _ in selectedCount += 1 }
            TargetInputInjector.suppressionHandler = { suppressionCalled = true }
            TargetInputInjector.isCapsLockOnProvider = { false }

            let message = RelayMessage.setInputSource(.thai, token: "test")
            TargetInputInjector.handle(message)

            #expect(selectedCount == 0)
            #expect(!suppressionCalled)
        }

        @Test func setInputSourceCleansUpCapsLockWhenAlreadyInDesiredStateIfCapsOn() {
            var selectedCount = 0
            var suppressionCalled = false

            TargetInputInjector.currentSourceProvider = { .thai }
            TargetInputInjector.sourceSelector = { _ in selectedCount += 1 }
            TargetInputInjector.suppressionHandler = { suppressionCalled = true }
            TargetInputInjector.isCapsLockOnProvider = { true }

            let message = RelayMessage.setInputSource(.thai, token: "test")
            TargetInputInjector.handle(message)

            #expect(selectedCount == 0)
            #expect(suppressionCalled)
        }

        @Test func setInputSourceDeduplicatesRapidSwitch() {
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
            #expect(selectedSources == [.thai])

            // Duplicate incoming message 20ms later
            virtualTime = 100.02
            TargetInputInjector.handle(message)
            #expect(selectedSources == [.thai])
        }
    }
}

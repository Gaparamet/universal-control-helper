import Testing
@testable import UniversalControlHelper

extension HelperSerialTests {
    @MainActor
    @Suite struct SettingsViewModelTests {
        @Test func unsavedPairingCodeSurvivesStatusRefresh() {
            let model = SettingsViewModel()
            model.update(snapshot: snapshot(pairingCode: "123456"))

            model.editPairingCode("654")
            model.update(snapshot: snapshot(pairingCode: "123456", status: .connectedSyncing))

            #expect(model.pairingCode == "654")
        }

        @Test func invalidPairingCodeShowsValidationFeedback() {
            let model = SettingsViewModel()
            model.update(snapshot: snapshot(pairingCode: "123456"))
            model.pairingCodeDidChange = { _ in false }

            model.editPairingCode("123")
            model.applyPairingCode()

            #expect(!model.pairingCodeIsValid)
            #expect(model.pairingCodeFeedbackKey == .invalid)
            #expect(model.pairingCode == "123")
        }

        @Test func appliedPairingCodeAcceptsFutureSnapshots() {
            let model = SettingsViewModel()
            model.update(snapshot: snapshot(pairingCode: "123456"))
            model.pairingCodeDidChange = { $0 == "654321" }

            model.editPairingCode("654321")
            model.applyPairingCode()
            model.update(snapshot: snapshot(pairingCode: "111111"))

            #expect(model.pairingCodeIsValid)
            #expect(model.pairingCode == "111111")
        }

        @Test func sourceCanRegeneratePairingCode() {
            let model = SettingsViewModel()
            model.update(snapshot: snapshot(pairingCode: "123456"))
            model.pairingCodeRegenerationRequested = { "654321" }

            model.regeneratePairingCode()

            #expect(model.pairingCode == "654321")
            #expect(model.pairingCodeFeedbackKey == .regenerated)
        }

        @Test func updateCheckInvokesCallback() {
            let model = SettingsViewModel()
            var updateCheckRequested = false
            model.updateCheckRequested = { updateCheckRequested = true }

            model.checkForUpdates()

            #expect(updateCheckRequested)
        }

        @Test func permissionRefreshUsesPhysicalMonitorResult() {
            let model = SettingsViewModel()
            model.update(snapshot: snapshot(pairingCode: "123456"))
            model.permissionRefreshRequested = { true }

            model.refreshInputMonitoring()

            #expect(model.inputMonitoringReady)
        }

        @Test func permissionResetInvokesRecoveryCallback() {
            let model = SettingsViewModel()
            var resetRequested = false
            model.permissionResetRequested = { resetRequested = true }

            model.resetInputMonitoring()

            #expect(resetRequested)
        }

        @Test func helperEnabledInvokesCallback() {
            let model = SettingsViewModel()
            var requestedValue: Bool?
            model.helperEnabledDidChange = { requestedValue = $0 }

            model.setHelperEnabled(false)

            #expect(!model.helperEnabled)
            #expect(requestedValue == false)
        }

        @Test func launchAtLoginUsesActualResult() {
            let model = SettingsViewModel()
            model.launchAtLoginDidChange = { requested in
                #expect(requested)
                return LaunchAtLoginChangeResult(state: .requiresApproval, feedbackKey: .requiresApproval)
            }

            model.setLaunchAtLogin(true)

            #expect(!model.launchAtLoginEnabled)
            #expect(model.launchAtLoginRequiresApproval)
            #expect(model.launchAtLoginFeedback == .requiresApproval)
        }

        @Test func languageSwitching() {
            let model = SettingsViewModel()
            var selected: AppLanguage?
            model.languageDidChange = { selected = $0 }

            model.selectLanguage(.en)
            #expect(model.language == .en)
            #expect(selected == .en)

            model.selectLanguage(.th)
            #expect(model.language == .th)
            #expect(selected == .th)
        }

        @Test func preventTargetCapsLockToggle() {
            let model = SettingsViewModel()
            var changedValue: Bool?
            model.preventTargetCapsLockDidChange = { changedValue = $0 }

            model.setPreventTargetCapsLock(false)
            #expect(!model.preventTargetCapsLock)
            #expect(changedValue == false)

            model.setPreventTargetCapsLock(true)
            #expect(model.preventTargetCapsLock)
            #expect(changedValue == true)
        }

        private func snapshot(
            pairingCode: String,
            status: ConnectionStatus = .searchingTarget,
            language: AppLanguage = .th,
            preventTargetCapsLock: Bool = true
        ) -> SettingsSnapshot {
            SettingsSnapshot(
                role: .source,
                pairingCode: pairingCode,
                connectionStatus: status,
                inputMonitoringReady: false,
                helperEnabled: true,
                currentVersion: "1.5.4",
                canCheckForUpdates: true,
                launchAtLoginState: .disabled,
                language: language,
                preventTargetCapsLock: preventTargetCapsLock
            )
        }
    }
}

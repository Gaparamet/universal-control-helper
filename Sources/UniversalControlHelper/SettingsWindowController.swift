import AppKit
import SwiftUI

struct SettingsSnapshot {
    let role: ComputerRole
    let pairingCode: String
    let connectionStatus: ConnectionStatus
    let inputMonitoringReady: Bool
    let helperEnabled: Bool
    let currentVersion: String
    let canCheckForUpdates: Bool
    let launchAtLoginState: LaunchAtLoginState
    let language: AppLanguage
    let preventTargetCapsLock: Bool
}

public enum PairingCodeFeedbackKey: Equatable {
    case applied
    case invalid
    case regenerated

    public func localized(for language: AppLanguage) -> String {
        switch self {
        case .applied:
            return L10n.string(.pairingCodeFeedbackApplied, language: language)
        case .invalid:
            return L10n.string(.pairingCodeFeedbackInvalid, language: language)
        case .regenerated:
            return L10n.string(.pairingCodeFeedbackRegenerated, language: language)
        }
    }
}

final class SettingsViewModel: ObservableObject {
    @Published private(set) var role: ComputerRole = .source
    @Published var pairingCode = ""
    @Published private(set) var connectionStatus: ConnectionStatus = .starting
    @Published private(set) var inputMonitoring = PermissionState.notDetermined
    @Published private(set) var inputMonitoringReady = false
    @Published private(set) var helperEnabled = true
    @Published private(set) var currentVersion = "-"
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var launchAtLoginEnabled = false
    @Published private(set) var launchAtLoginRequiresApproval = false
    @Published private(set) var launchAtLoginFeedback: LaunchAtLoginFeedbackKey?
    @Published var pairingCodeFeedbackKey: PairingCodeFeedbackKey?
    @Published var pairingCodeIsValid = true
    @Published private(set) var language: AppLanguage = .th
    @Published private(set) var preventTargetCapsLock = true
    private var pairingCodeIsDirty = false

    var roleDidChange: ((ComputerRole) -> Void)?
    var pairingCodeDidChange: ((String) -> Bool)?
    var pairingCodeRegenerationRequested: (() -> String)?
    var permissionRefreshRequested: (() -> Bool)?
    var permissionResetRequested: (() -> Void)?
    var helperEnabledDidChange: ((Bool) -> Void)?
    var updateCheckRequested: (() -> Void)?
    var launchAtLoginDidChange: ((Bool) -> LaunchAtLoginChangeResult)?
    var languageDidChange: ((AppLanguage) -> Void)?
    var preventTargetCapsLockDidChange: ((Bool) -> Void)?

    func update(snapshot: SettingsSnapshot) {
        role = snapshot.role
        if !pairingCodeIsDirty {
            pairingCode = snapshot.pairingCode
        }
        connectionStatus = snapshot.connectionStatus
        inputMonitoringReady = snapshot.inputMonitoringReady
        inputMonitoring = AppPermissions.inputMonitoring
        helperEnabled = snapshot.helperEnabled
        currentVersion = snapshot.currentVersion
        canCheckForUpdates = snapshot.canCheckForUpdates
        language = snapshot.language
        preventTargetCapsLock = snapshot.preventTargetCapsLock
        applyLaunchAtLoginState(snapshot.launchAtLoginState)
    }

    func setPreventTargetCapsLock(_ enabled: Bool) {
        preventTargetCapsLock = enabled
        preventTargetCapsLockDidChange?(enabled)
    }

    func selectLanguage(_ newLanguage: AppLanguage) {
        guard language != newLanguage else { return }
        language = newLanguage
        languageDidChange?(newLanguage)
    }

    func selectRole(_ newRole: ComputerRole) {
        role = newRole
        pairingCodeIsDirty = false
        pairingCodeFeedbackKey = nil
        roleDidChange?(newRole)
    }

    func applyPairingCode() {
        let code = pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if pairingCodeDidChange?(code) == true {
            pairingCode = code
            pairingCodeIsDirty = false
            pairingCodeIsValid = true
            pairingCodeFeedbackKey = .applied
        } else {
            pairingCodeIsValid = false
            pairingCodeFeedbackKey = .invalid
        }
    }

    func editPairingCode(_ code: String) {
        pairingCode = code
        pairingCodeIsDirty = true
        pairingCodeFeedbackKey = nil
        pairingCodeIsValid = true
    }

    func regeneratePairingCode() {
        guard let code = pairingCodeRegenerationRequested?(), !code.isEmpty else { return }
        pairingCode = code
        pairingCodeIsDirty = false
        pairingCodeIsValid = true
        pairingCodeFeedbackKey = .regenerated
    }

    func checkForUpdates() {
        updateCheckRequested?()
    }

    func refreshInputMonitoring() {
        if let permissionRefreshRequested {
            inputMonitoringReady = permissionRefreshRequested()
        }
        inputMonitoring = AppPermissions.inputMonitoring
    }

    func resetInputMonitoring() {
        permissionResetRequested?()
    }

    func setHelperEnabled(_ enabled: Bool) {
        helperEnabled = enabled
        helperEnabledDidChange?(enabled)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        guard let result = launchAtLoginDidChange?(enabled) else { return }
        applyLaunchAtLoginState(result.state)
        launchAtLoginFeedback = result.feedbackKey
    }

    func openLoginItemsSettings() {
        LaunchAtLogin.openSystemSettings()
    }

    private func applyLaunchAtLoginState(_ state: LaunchAtLoginState) {
        launchAtLoginEnabled = state.isEnabled
        launchAtLoginRequiresApproval = state == .requiresApproval
        if state != .requiresApproval {
            launchAtLoginFeedback = nil
        }
    }
}

final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    var roleDidChange: ((ComputerRole) -> Void)?
    var pairingCodeDidChange: ((String) -> Bool)?
    var pairingCodeRegenerationRequested: (() -> String)?
    var permissionRefreshRequested: (() -> Bool)?
    var permissionResetRequested: (() -> Void)?
    var helperEnabledDidChange: ((Bool) -> Void)?
    var updateCheckRequested: (() -> Void)?
    var launchAtLoginDidChange: ((Bool) -> LaunchAtLoginChangeResult)?
    var languageDidChange: ((AppLanguage) -> Void)?
    var preventTargetCapsLockDidChange: ((Bool) -> Void)?
    var windowDidClose: (() -> Void)?

    private let model = SettingsViewModel()

    init() {
        let rootView = SettingsView(model: model)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = L10n.string(.settingsWindowTitle, language: .th)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 600, height: 760))
        window.minSize = NSSize(width: 560, height: 680)
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
        window.delegate = self
        model.roleDidChange = { [weak self] role in
            self?.resize(for: role)
            self?.roleDidChange?(role)
        }
        model.pairingCodeDidChange = { [weak self] code in
            self?.pairingCodeDidChange?(code) ?? false
        }
        model.pairingCodeRegenerationRequested = { [weak self] in
            self?.pairingCodeRegenerationRequested?() ?? ""
        }
        model.permissionRefreshRequested = { [weak self] in
            self?.permissionRefreshRequested?() ?? false
        }
        model.permissionResetRequested = { [weak self] in
            self?.permissionResetRequested?()
        }
        model.helperEnabledDidChange = { [weak self] enabled in
            self?.helperEnabledDidChange?(enabled)
        }
        model.updateCheckRequested = { [weak self] in
            self?.updateCheckRequested?()
        }
        model.launchAtLoginDidChange = { [weak self] enabled in
            self?.launchAtLoginDidChange?(enabled)
                ?? LaunchAtLoginChangeResult(state: .unavailable, feedbackKey: nil)
        }
        model.languageDidChange = { [weak self] lang in
            self?.window?.title = L10n.string(.settingsWindowTitle, language: lang)
            self?.languageDidChange?(lang)
        }
        model.preventTargetCapsLockDidChange = { [weak self] enabled in
            self?.preventTargetCapsLockDidChange?(enabled)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(snapshot: SettingsSnapshot) {
        model.update(snapshot: snapshot)
        window?.title = L10n.string(.settingsWindowTitle, language: snapshot.language)
        resize(for: snapshot.role)
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func update(snapshot: SettingsSnapshot) {
        model.update(snapshot: snapshot)
        window?.title = L10n.string(.settingsWindowTitle, language: snapshot.language)
    }

    func windowWillClose(_ notification: Notification) {
        windowDidClose?()
    }

    private func resize(for role: ComputerRole) {
        let height: CGFloat = role == .source ? 760 : 620
        window?.minSize = NSSize(width: 560, height: role == .source ? 700 : 580)
        window?.setContentSize(NSSize(width: 600, height: height))
    }
}

private struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            generalSection
            connectionSection
            if model.role == .source {
                inputPermissionSection
            }
            softwareUpdateSection
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(
            minWidth: 560,
            idealWidth: 600,
            minHeight: model.role == .source ? 700 : 580,
            idealHeight: model.role == .source ? 760 : 620
        )
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .accessibilityLabel(L10n.string(.appIconAccessibility, language: model.language))

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string(.appName, language: model.language))
                    .font(.title2.weight(.semibold))
                Text(L10n.string(.appSubtitle, language: model.language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var generalSection: some View {
        GroupBox(L10n.string(.sectionGeneral, language: model.language)) {
            VStack(alignment: .leading, spacing: 14) {
                Picker(
                    L10n.string(.labelAppLanguage, language: model.language),
                    selection: Binding(
                        get: { model.language },
                        set: { model.selectLanguage($0) }
                    )
                ) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)

                Divider()

                Toggle(
                    L10n.string(.enableHelper, language: model.language),
                    isOn: Binding(
                        get: { model.helperEnabled },
                        set: { model.setHelperEnabled($0) }
                    )
                )
                .accessibilityLabel(L10n.string(.enableHelper, language: model.language))

                Divider()

                Toggle(
                    L10n.string(.launchAtLogin, language: model.language),
                    isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
                .accessibilityLabel(L10n.string(.launchAtLogin, language: model.language))

                if let feedback = model.launchAtLoginFeedback {
                    HStack(alignment: .firstTextBaseline) {
                        Text(feedback.localized(for: model.language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if model.launchAtLoginRequiresApproval {
                            Button(L10n.string(.openLoginSettings, language: model.language)) {
                                model.openLoginItemsSettings()
                            }
                            .controlSize(.small)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    private var connectionSection: some View {
        GroupBox(L10n.string(.sectionConnection, language: model.language)) {
            VStack(alignment: .leading, spacing: 14) {
                Picker(
                    L10n.string(.rolePickerLabel, language: model.language),
                    selection: Binding(
                        get: { model.role },
                        set: { model.selectRole($0) }
                    )
                ) {
                    Text(L10n.string(.roleSource, language: model.language)).tag(ComputerRole.source)
                    Text(L10n.string(.roleTarget, language: model.language)).tag(ComputerRole.target)
                }
                .pickerStyle(.segmented)

                Divider()

                LabeledContent(L10n.string(.connectionStatusLabel, language: model.language)) {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(connectionColor)
                            .frame(width: 9, height: 9)
                        Text(model.connectionStatus.localized(for: model.language))
                            .lineLimit(1)
                    }
                }

                pairingCodeRow

                if let feedback = model.pairingCodeFeedbackKey {
                    Text(feedback.localized(for: model.language))
                        .font(.caption)
                        .foregroundStyle(model.pairingCodeIsValid ? Color.green : Color.red)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(
                        model.role == .source
                            ? L10n.string(.pairingCodeHintSource, language: model.language)
                            : L10n.string(.pairingCodeHintTarget, language: model.language)
                    )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Text(
                    model.role == .source
                        ? L10n.string(.roleExplanationSource, language: model.language)
                        : L10n.string(.roleExplanationTarget, language: model.language)
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if model.role == .target {
                    Divider()

                    Toggle(
                        isOn: Binding(
                            get: { model.preventTargetCapsLock },
                            set: { model.setPreventTargetCapsLock($0) }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.string(.preventTargetCapsLockTitle, language: model.language))
                            Text(L10n.string(.preventTargetCapsLockSubtitle, language: model.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    @ViewBuilder
    private var pairingCodeRow: some View {
        if model.role == .source {
            LabeledContent(L10n.string(.pairingCodeLabel, language: model.language)) {
                HStack(spacing: 10) {
                    Text(model.pairingCode)
                        .font(.system(.body, design: .monospaced).weight(.semibold))
                        .textSelection(.enabled)
                    Button(L10n.string(.regenerateCode, language: model.language)) {
                        model.regeneratePairingCode()
                    }
                    .accessibilityLabel(L10n.string(.regenerateCodeAccessibility, language: model.language))
                }
            }
        } else {
            LabeledContent(L10n.string(.pairingCodeLabel, language: model.language)) {
                HStack(spacing: 8) {
                    TextField(
                        L10n.string(.pairingCodePlaceholder, language: model.language),
                        text: Binding(
                            get: { model.pairingCode },
                            set: { model.editPairingCode($0) }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.system(.body, design: .monospaced).weight(.medium))
                    .frame(width: 130)
                    .onSubmit { model.applyPairingCode() }
                    .accessibilityLabel(L10n.string(.pairingCodeLabel, language: model.language))

                    Button(L10n.string(.applyCode, language: model.language)) {
                        model.applyPairingCode()
                    }
                    .accessibilityLabel(L10n.string(.applyCodeAccessibility, language: model.language))
                }
            }
        }
    }

    private var inputPermissionSection: some View {
        GroupBox(L10n.string(.sectionInputPermissions, language: model.language)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(model.inputMonitoringReady ? Color.green : Color.red)
                        .frame(width: 9, height: 9)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.string(.inputMonitoringLabel, language: model.language))
                            .fontWeight(.medium)
                        Text(inputMonitoringDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(L10n.string(.openSettings, language: model.language)) {
                        AppPermissions.openInputMonitoringSettings()
                    }
                    .accessibilityLabel(L10n.string(.openInputSettingsAccessibility, language: model.language))
                }

                Text(L10n.string(.permissionHint, language: model.language))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    if !model.inputMonitoringReady {
                        Button(L10n.string(.resetPermissions, language: model.language), role: .destructive) {
                            model.resetInputMonitoring()
                        }
                        .controlSize(.small)

                        Button(L10n.string(.revealApp, language: model.language)) {
                            AppPermissions.revealCurrentApplication()
                        }
                        .controlSize(.small)
                    }
                    Spacer()
                    Button {
                        model.refreshInputMonitoring()
                    } label: {
                        Label(L10n.string(.recheckPermission, language: model.language), systemImage: "arrow.clockwise")
                    }
                    .controlSize(.small)
                }
            }
            .padding(8)
        }
    }

    private var softwareUpdateSection: some View {
        GroupBox(L10n.string(.sectionSoftwareUpdate, language: model.language)) {
            LabeledContent(L10n.string(.currentVersion, language: model.language)) {
                HStack(spacing: 10) {
                    Text(model.currentVersion)
                        .foregroundStyle(.secondary)
                    Button(L10n.string(.checkForUpdates, language: model.language)) {
                        model.checkForUpdates()
                    }
                    .disabled(!model.canCheckForUpdates)
                    .accessibilityLabel(L10n.string(.checkForUpdatesAccessibility, language: model.language))
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var connectionColor: Color {
        if model.connectionStatus.isConnected {
            return .green
        }
        if model.connectionStatus.isError {
            return .red
        }
        return .orange
    }

    private var inputMonitoringDescription: String {
        if model.inputMonitoringReady {
            return L10n.string(.permissionDescReady, language: model.language)
        }
        switch model.inputMonitoring {
        case .granted:
            return L10n.string(.permissionDescGrantedNotStarted, language: model.language)
        case .denied:
            return L10n.string(.permissionDescDenied, language: model.language)
        case .notDetermined:
            return L10n.string(.permissionDescNotDetermined, language: model.language)
        }
    }
}

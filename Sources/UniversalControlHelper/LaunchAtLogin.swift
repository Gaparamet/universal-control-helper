import AppKit
import ServiceManagement

enum LaunchAtLoginState: Equatable {
    case enabled
    case disabled
    case requiresApproval
    case unavailable

    var isEnabled: Bool { self == .enabled }
}

struct LaunchAtLoginChangeResult: Equatable {
    let state: LaunchAtLoginState
    let feedbackKey: LaunchAtLoginFeedbackKey?
}

enum LaunchAtLogin {
    static var state: LaunchAtLoginState {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .enabled
        case .notRegistered:
            return .disabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    static func setEnabled(_ enabled: Bool) -> LaunchAtLoginChangeResult {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            return LaunchAtLoginChangeResult(
                state: state,
                feedbackKey: .error(error.localizedDescription)
            )
        }

        let currentState = state
        let feedback: LaunchAtLoginFeedbackKey?
        switch currentState {
        case .requiresApproval:
            feedback = .requiresApproval
        case .unavailable:
            feedback = .unavailable
        case .enabled, .disabled:
            feedback = nil
        }
        return LaunchAtLoginChangeResult(state: currentState, feedbackKey: feedback)
    }

    static func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

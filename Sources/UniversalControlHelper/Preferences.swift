import Foundation
import UniversalControlCore

public enum AppLanguage: String, CaseIterable, Identifiable {
    case th = "th"
    case en = "en"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .th: return "ไทย (TH)"
        case .en: return "English (ENG)"
        }
    }
}

enum ComputerRole: String {
    case source
    case target
}

final class Preferences {
    private enum Key {
        static let role = "computerRole"
        static let pairingCode = "pairingCode"
        static let helperEnabled = "helperEnabled"
        static let appLanguage = "appLanguage"
        static let preventTargetCapsLock = "preventTargetCapsLock"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.string(forKey: Key.role) == nil {
            defaults.set(ComputerRole.source.rawValue, forKey: Key.role)
        }
        if defaults.object(forKey: Key.helperEnabled) == nil {
            defaults.set(true, forKey: Key.helperEnabled)
        }
        if defaults.string(forKey: Key.appLanguage) == nil {
            defaults.set(AppLanguage.th.rawValue, forKey: Key.appLanguage)
        }
        if defaults.object(forKey: Key.preventTargetCapsLock) == nil {
            defaults.set(true, forKey: Key.preventTargetCapsLock)
        }
        if let code = defaults.string(forKey: Key.pairingCode), PairingCode.isValid(code) {
            return
        }
        defaults.set(PairingCode.generate(), forKey: Key.pairingCode)
    }

    var role: ComputerRole {
        get { ComputerRole(rawValue: defaults.string(forKey: Key.role) ?? "") ?? .source }
        set { defaults.set(newValue.rawValue, forKey: Key.role) }
    }

    var pairingCode: String {
        get { defaults.string(forKey: Key.pairingCode) ?? "000000" }
        set {
            precondition(PairingCode.isValid(newValue))
            defaults.set(newValue, forKey: Key.pairingCode)
        }
    }

    var helperEnabled: Bool {
        get { defaults.bool(forKey: Key.helperEnabled) }
        set { defaults.set(newValue, forKey: Key.helperEnabled) }
    }

    var language: AppLanguage {
        get {
            guard let raw = defaults.string(forKey: Key.appLanguage),
                  let lang = AppLanguage(rawValue: raw) else {
                return .th
            }
            return lang
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.appLanguage)
        }
    }

    var preventTargetCapsLock: Bool {
        get {
            if defaults.object(forKey: Key.preventTargetCapsLock) == nil {
                return true
            }
            return defaults.bool(forKey: Key.preventTargetCapsLock)
        }
        set {
            defaults.set(newValue, forKey: Key.preventTargetCapsLock)
        }
    }
}

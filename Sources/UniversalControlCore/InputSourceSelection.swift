import Foundation

public struct InputSourceDescriptor: Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public enum InputSourceState: String, Codable, Equatable, Sendable {
    case abc
    case thai
    case korean
}

public enum InputSourceSelection {
    public static func state(
        id: String,
        name: String = ""
    ) -> InputSourceState? {
        let normalizedID = id.lowercased()
        let normalizedName = name.lowercased()

        // Thai input sources
        if normalizedID.contains("thai")
            || normalizedName.contains("thai")
            || normalizedName.contains("ไทย")
            || normalizedID.contains("pattachote")
            || normalizedID.contains("kedmanee") {
            return .thai
        }

        // Korean input sources
        if normalizedID.contains("korean")
            || normalizedID.contains("hangul")
            || normalizedID.contains("2set")
            || normalizedName.contains("두벌식") {
            return .korean
        }

        // ABC / English input sources
        if id == "com.apple.keylayout.ABC"
            || normalizedID.contains("keylayout.us")
            || normalizedID.contains("keylayout.british")
            || name.caseInsensitiveCompare("ABC") == .orderedSame
            || name.caseInsensitiveCompare("U.S.") == .orderedSame
            || name.caseInsensitiveCompare("US") == .orderedSame {
            return .abc
        }
        return nil
    }

    public static func targetID(
        for state: InputSourceState,
        candidates: [InputSourceDescriptor]
    ) -> String? {
        switch state {
        case .abc:
            if let id = candidates.first(where: { $0.id == "com.apple.keylayout.ABC" })?.id { return id }
            if let id = candidates.first(where: { $0.name.caseInsensitiveCompare("ABC") == .orderedSame })?.id { return id }
            if let id = candidates.first(where: { $0.id == "com.apple.keylayout.US" })?.id { return id }
            if let id = candidates.first(where: { $0.name.caseInsensitiveCompare("U.S.") == .orderedSame })?.id { return id }
            if let id = candidates.first(where: { $0.id.lowercased().contains("keylayout.us") })?.id { return id }
            return candidates.first { InputSourceSelection.state(id: $0.id, name: $0.name) == .abc }?.id
        case .thai:
            return candidates.first {
                let id = $0.id.lowercased()
                return id == "com.apple.keylayout.thai"
            }?.id ?? candidates.first {
                let id = $0.id.lowercased()
                let name = $0.name.lowercased()
                return id.contains("thai") || name.contains("thai") || name.contains("ไทย")
            }?.id ?? candidates.first { InputSourceSelection.state(id: $0.id, name: $0.name) == .thai }?.id
        case .korean:
            return candidates.first {
                let id = $0.id.lowercased()
                return id.contains("2setkorean") || id.contains("2sethangul")
            }?.id ?? candidates.first {
                let id = $0.id.lowercased()
                return id.contains("korean") || id.contains("hangul")
            }?.id ?? candidates.first { InputSourceSelection.state(id: $0.id, name: $0.name) == .korean }?.id
        }
    }

    public static func targetID(
        currentID: String,
        candidates: [InputSourceDescriptor]
    ) -> String? {
        let currentName = candidates.first { $0.id == currentID }?.name ?? ""
        let currentState = state(id: currentID, name: currentName)
        let targetState: InputSourceState
        if currentState == .abc {
            // If current is ABC, toggle to Thai (or Korean if user has Korean candidates)
            let hasThai = candidates.contains {
                let id = $0.id.lowercased()
                let name = $0.name.lowercased()
                return id.contains("thai") || name.contains("thai") || name.contains("ไทย")
            }
            if hasThai {
                targetState = .thai
            } else {
                targetState = .korean
            }
        } else {
            // If current is Thai (or Korean), toggle to ABC
            targetState = .abc
        }
        return targetID(for: targetState, candidates: candidates)
    }
}

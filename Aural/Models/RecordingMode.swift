import Foundation

enum RecordingMode: String, CaseIterable, Identifiable {
    case holdOnly = "Hold Only"
    case tapToLock = "Tap to Lock"
    case hybrid = "Hybrid"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .holdOnly:
            return "Hold key to record, release to stop"
        case .tapToLock:
            return "Quick tap to start/stop locked recording"
        case .hybrid:
            return "Hold for temporary, tap for locked recording"
        }
    }
}

struct RecordingModePreferences {
    static var mode: RecordingMode {
        get {
            let stored = UserDefaults.standard.string(forKey: UserDefaultsKeys.recordingMode) ?? RecordingMode.hybrid.rawValue
            return RecordingMode(rawValue: stored) ?? .hybrid
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.recordingMode)
        }
    }

    static var quickTapThreshold: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: UserDefaultsKeys.quickTapThreshold)
            return stored > 0 ? stored : KeyboardConstants.quickTapThresholdSeconds
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.quickTapThreshold)
        }
    }
}

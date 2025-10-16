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
    static let key = "recording_mode"
    static let quickTapThresholdKey = "quick_tap_threshold"

    static var mode: RecordingMode {
        get {
            let stored = UserDefaults.standard.string(forKey: key) ?? RecordingMode.hybrid.rawValue
            return RecordingMode(rawValue: stored) ?? .hybrid
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }

    static var quickTapThreshold: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: quickTapThresholdKey)
            return stored > 0 ? stored : 0.3
        }
        set {
            UserDefaults.standard.set(newValue, forKey: quickTapThresholdKey)
        }
    }
}

import Foundation

enum WidgetDisplayMode: String, CaseIterable, Codable, Identifiable {
    case none = "None"
    case simple = "Simple"
    case waveform = "Waveform"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .none:
            return "No floating widget displayed"
        case .simple:
            return "Compact widget with mic icon"
        case .waveform:
            return "Animated sound waves during recording"
        }
    }

    /// The default mode for new users
    static var defaultMode: WidgetDisplayMode {
        .waveform
    }
}

import Foundation
import Carbon

// MARK: - Hotkey Configuration

struct HotkeyConfiguration: Equatable {
    let keyCode: CGKeyCode
    let modifiers: CGEventFlags

    static let `default` = HotkeyConfiguration(
        keyCode: KeyboardConstants.fnKeyCode,
        modifiers: .maskSecondaryFn
    )

    var displayString: String {
        var components: [String] = []

        if modifiers.contains(.maskCommand) {
            components.append("⌘")
        }
        if modifiers.contains(.maskAlternate) {
            components.append("⌥")
        }
        if modifiers.contains(.maskControl) {
            components.append("⌃")
        }
        if modifiers.contains(.maskShift) {
            components.append("⇧")
        }
        if modifiers.contains(.maskSecondaryFn) {
            components.append("Fn")
        }

        if let keyName = KeyCodeMapper.nameForKeyCode(keyCode) {
            components.append(keyName)
        } else {
            components.append("Key \(keyCode)")
        }

        return components.joined(separator: "")
    }

    func matches(event: CGEvent) -> Bool {
        let eventKeyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let eventFlags = event.flags
        let relevantFlags: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift, .maskSecondaryFn]
        let eventModifiers = eventFlags.intersection(relevantFlags)

        return CGKeyCode(eventKeyCode) == keyCode && eventModifiers == modifiers
    }
}

// MARK: - Codable Conformance

extension HotkeyConfiguration: Codable {
    enum CodingKeys: String, CodingKey {
        case keyCode
        case modifiers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keyCodeValue = try container.decode(UInt16.self, forKey: .keyCode)
        let modifiersValue = try container.decode(UInt64.self, forKey: .modifiers)

        self.keyCode = CGKeyCode(keyCodeValue)
        self.modifiers = CGEventFlags(rawValue: modifiersValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifiers.rawValue, forKey: .modifiers)
    }
}

// MARK: - Key Code Mapper

enum KeyCodeMapper {
    static func nameForKeyCode(_ keyCode: CGKeyCode) -> String? {
        let keyCodeMap: [CGKeyCode: String] = [
            // Letters
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
            45: "N", 46: "M",

            // Numbers
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",

            // Function keys
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",

            // Special keys
            36: "↩", 48: "⇥", 49: "Space", 51: "⌫",
            53: "⎋", 117: "⌦", 115: "↖", 119: "↘", 116: "⇞", 121: "⇟",

            // Arrows
            123: "←", 124: "→", 125: "↓", 126: "↑",

            // Punctuation
            27: "-", 24: "=", 33: "[", 30: "]", 42: "\\",
            41: ";", 39: "'", 43: ",", 47: ".", 44: "/"
        ]

        return keyCodeMap[keyCode]
    }
}

// MARK: - Hotkey Repository

final class HotkeyRepository {
    private let key = UserDefaultsKeys.customHotkey

    func save(_ configuration: HotkeyConfiguration) {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func load() -> HotkeyConfiguration {
        guard let data = UserDefaults.standard.data(forKey: key),
              let configuration = try? JSONDecoder().decode(HotkeyConfiguration.self, from: data) else {
            return .default
        }
        return configuration
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

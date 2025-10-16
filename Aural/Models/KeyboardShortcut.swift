import AppKit
import Carbon

// MARK: - Keyboard Shortcut Action

enum ShortcutAction: String, CaseIterable, Identifiable, Codable {
    case copyLastTranscription = "Copy Last Transcription"
    case showHideWindow = "Show/Hide Window"
    case openSettings = "Open Settings"
    case clearHistory = "Clear History"

    var id: String { rawValue }

    var defaultShortcut: KeyboardShortcutDefinition? {
        switch self {
        case .copyLastTranscription:
            return KeyboardShortcutDefinition(
                keyCode: 8,
                modifiers: [.maskCommand, .maskShift]
            )
        case .showHideWindow:
            return KeyboardShortcutDefinition(
                keyCode: 49,
                modifiers: [.maskCommand, .maskAlternate]
            )
        case .openSettings:
            return KeyboardShortcutDefinition(
                keyCode: 38,
                modifiers: [.maskCommand]
            )
        case .clearHistory:
            return nil
        }
    }

    var description: String {
        switch self {
        case .copyLastTranscription:
            return "Copy the most recent transcription to clipboard"
        case .showHideWindow:
            return "Toggle main window visibility"
        case .openSettings:
            return "Open settings window"
        case .clearHistory:
            return "Clear all transcription history"
        }
    }
}

// MARK: - Keyboard Shortcut Definition

struct KeyboardShortcutDefinition: Codable, Equatable {
    let keyCode: CGKeyCode
    let modifiers: CGEventFlags

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

        if let keyName = KeyCodeMapper.nameForKeyCode(keyCode) {
            components.append(keyName)
        } else {
            components.append("Key \(keyCode)")
        }

        return components.joined(separator: "")
    }

    func matches(keyCode: CGKeyCode, modifiers: NSEvent.ModifierFlags) -> Bool {
        guard self.keyCode == keyCode else { return false }

        var expectedFlags: NSEvent.ModifierFlags = []
        if self.modifiers.contains(.maskCommand) {
            expectedFlags.insert(.command)
        }
        if self.modifiers.contains(.maskAlternate) {
            expectedFlags.insert(.option)
        }
        if self.modifiers.contains(.maskControl) {
            expectedFlags.insert(.control)
        }
        if self.modifiers.contains(.maskShift) {
            expectedFlags.insert(.shift)
        }

        let relevantModifiers = modifiers.intersection([.command, .option, .control, .shift])
        return relevantModifiers == expectedFlags
    }
}

extension KeyboardShortcutDefinition {
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

// MARK: - Keyboard Shortcuts Configuration

struct KeyboardShortcutsConfiguration: Codable {
    var shortcuts: [ShortcutAction: KeyboardShortcutDefinition]
    var isEnabled: Bool

    init(shortcuts: [ShortcutAction: KeyboardShortcutDefinition] = [:], isEnabled: Bool = true) {
        self.shortcuts = shortcuts
        self.isEnabled = isEnabled
    }

    mutating func setShortcut(_ definition: KeyboardShortcutDefinition?, for action: ShortcutAction) {
        if let definition = definition {
            shortcuts[action] = definition
        } else {
            shortcuts.removeValue(forKey: action)
        }
    }

    func shortcut(for action: ShortcutAction) -> KeyboardShortcutDefinition? {
        return shortcuts[action] ?? action.defaultShortcut
    }

    static let `default`: KeyboardShortcutsConfiguration = {
        var shortcuts: [ShortcutAction: KeyboardShortcutDefinition] = [:]
        for action in ShortcutAction.allCases {
            if let defaultShortcut = action.defaultShortcut {
                shortcuts[action] = defaultShortcut
            }
        }
        return KeyboardShortcutsConfiguration(shortcuts: shortcuts, isEnabled: true)
    }()
}

// MARK: - Keyboard Shortcuts Repository

final class KeyboardShortcutsRepository {
    private let key = "keyboard_shortcuts_configuration"

    func save(_ configuration: KeyboardShortcutsConfiguration) {
        if let encoded = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func load() -> KeyboardShortcutsConfiguration {
        guard let data = UserDefaults.standard.data(forKey: key),
              let configuration = try? JSONDecoder().decode(KeyboardShortcutsConfiguration.self, from: data) else {
            return .default
        }
        return configuration
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}

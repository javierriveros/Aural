import Foundation

// MARK: - Voice Command

struct VoiceCommand {
    let triggers: [String]
    let action: CommandAction
    let caseSensitive: Bool

    init(triggers: [String], action: CommandAction, caseSensitive: Bool = false) {
        self.triggers = triggers
        self.action = action
        self.caseSensitive = caseSensitive
    }
}

// MARK: - Command Action

enum CommandAction {
    case insertText(String)
    case newLine
    case newParagraph
    case capitalizeNext
    case uppercaseNext
    case lowercaseNext
    case deleteLastWord
    case deleteLastSentence
}

// MARK: - Voice Command Registry

enum VoiceCommandRegistry {
    static let allCommands: [VoiceCommand] = [
        VoiceCommand(triggers: ["comma"], action: .insertText(",")),
        VoiceCommand(triggers: ["period", "full stop", "dot"], action: .insertText(".")),
        VoiceCommand(triggers: ["question mark"], action: .insertText("?")),
        VoiceCommand(triggers: ["exclamation mark", "exclamation point"], action: .insertText("!")),
        VoiceCommand(triggers: ["colon"], action: .insertText(":")),
        VoiceCommand(triggers: ["semicolon"], action: .insertText(";")),
        VoiceCommand(triggers: ["quote", "quotation mark"], action: .insertText("\"")),
        VoiceCommand(triggers: ["single quote"], action: .insertText("'")),
        VoiceCommand(triggers: ["open parenthesis", "left parenthesis"], action: .insertText("(")),
        VoiceCommand(triggers: ["close parenthesis", "right parenthesis"], action: .insertText(")")),
        VoiceCommand(triggers: ["open bracket", "left bracket"], action: .insertText("[")),
        VoiceCommand(triggers: ["close bracket", "right bracket"], action: .insertText("]")),
        VoiceCommand(triggers: ["open brace", "left brace"], action: .insertText("{")),
        VoiceCommand(triggers: ["close brace", "right brace"], action: .insertText("}")),
        VoiceCommand(triggers: ["hyphen", "dash"], action: .insertText("-")),
        VoiceCommand(triggers: ["underscore"], action: .insertText("_")),
        VoiceCommand(triggers: ["at sign"], action: .insertText("@")),
        VoiceCommand(triggers: ["hashtag", "pound sign"], action: .insertText("#")),
        VoiceCommand(triggers: ["dollar sign"], action: .insertText("$")),
        VoiceCommand(triggers: ["percent sign"], action: .insertText("%")),
        VoiceCommand(triggers: ["ampersand", "and sign"], action: .insertText("&")),
        VoiceCommand(triggers: ["asterisk", "star"], action: .insertText("*")),
        VoiceCommand(triggers: ["plus sign"], action: .insertText("+")),
        VoiceCommand(triggers: ["equals sign"], action: .insertText("=")),
        VoiceCommand(triggers: ["slash", "forward slash"], action: .insertText("/")),
        VoiceCommand(triggers: ["backslash"], action: .insertText("\\")),
        VoiceCommand(triggers: ["vertical bar", "pipe"], action: .insertText("|")),
        VoiceCommand(triggers: ["tilde"], action: .insertText("~")),
        VoiceCommand(triggers: ["caret"], action: .insertText("^")),
        VoiceCommand(triggers: ["less than", "left angle bracket"], action: .insertText("<")),
        VoiceCommand(triggers: ["greater than", "right angle bracket"], action: .insertText(">")),

        VoiceCommand(triggers: ["new line", "line break"], action: .newLine),
        VoiceCommand(triggers: ["new paragraph", "paragraph break"], action: .newParagraph),

        VoiceCommand(triggers: ["cap", "capitalize", "capital"], action: .capitalizeNext),
        VoiceCommand(triggers: ["all caps", "uppercase", "upper case"], action: .uppercaseNext),
        VoiceCommand(triggers: ["no caps", "lowercase", "lower case"], action: .lowercaseNext),

        VoiceCommand(triggers: ["scratch that", "delete word"], action: .deleteLastWord),
        VoiceCommand(triggers: ["delete sentence", "scratch sentence"], action: .deleteLastSentence)
    ]

    static func findCommand(in text: String) -> (command: VoiceCommand, trigger: String, range: Range<String.Index>)? {
        let lowercasedText = text.lowercased()

        for command in allCommands {
            for trigger in command.triggers {
                let searchText = command.caseSensitive ? text : lowercasedText
                let searchTrigger = command.caseSensitive ? trigger : trigger.lowercased()

                if let range = searchText.range(of: "\\b\(NSRegularExpression.escapedPattern(for: searchTrigger))\\b",
                                                 options: .regularExpression) {
                    return (command, trigger, range)
                }
            }
        }

        return nil
    }
}

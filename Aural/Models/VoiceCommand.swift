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

struct CommandMatch {
    let command: VoiceCommand
    let trigger: String
    let range: Range<String.Index>
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

    private struct CachedTrigger {
        let command: VoiceCommand
        let trigger: String
        let regex: NSRegularExpression
    }

    private static let cachedTriggers: [CachedTrigger] = {
        var triggers: [CachedTrigger] = []
        for command in allCommands {
            for trigger in command.triggers {
                let pattern = "\\b\(NSRegularExpression.escapedPattern(for: command.caseSensitive ? trigger : trigger.lowercased()))\\b"
                let options: NSRegularExpression.Options = command.caseSensitive ? [] : [.caseInsensitive]
                
                if let regex = try? NSRegularExpression(pattern: pattern, options: options) {
                    triggers.append(CachedTrigger(
                        command: command,
                        trigger: trigger,
                        regex: regex
                    ))
                }
            }
        }
        return triggers
    }()

    static func findCommand(in text: String) -> CommandMatch? {
        for cached in cachedTriggers {
            let range = NSRange(text.startIndex..., in: text)
            if let match = cached.regex.firstMatch(in: text, options: [], range: range),
               let range = Range(match.range, in: text) {
                return CommandMatch(command: cached.command, trigger: cached.trigger, range: range)
            }
        }
        return nil
    }
}

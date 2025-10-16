import Foundation

final class VoiceCommandProcessor {
    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: UserDefaultsKeys.voiceCommandsEnabled)
    }

    func process(_ text: String) -> String {
        guard isEnabled else { return text }

        var result = text
        var previousLength = result.count

        while true {
            guard let match = VoiceCommandRegistry.findCommand(in: result) else {
                break
            }

            result = applyCommand(
                to: result,
                command: match.command,
                trigger: match.trigger,
                range: match.range
            )

            if result.count == previousLength {
                break
            }

            previousLength = result.count
        }

        return result
    }

    private func applyCommand(
        to text: String,
        command: VoiceCommand,
        trigger: String,
        range: Range<String.Index>
    ) -> String {
        var result = text

        switch command.action {
        case .insertText(let replacement):
            result = handleInsertText(in: text, range: range, replacement: replacement)

        case .newLine:
            result = handleNewLine(in: text, range: range)

        case .newParagraph:
            result = handleNewParagraph(in: text, range: range)

        case .capitalizeNext:
            result = handleCapitalizeNext(in: text, range: range)

        case .uppercaseNext:
            result = handleUppercaseNext(in: text, range: range)

        case .lowercaseNext:
            result = handleLowercaseNext(in: text, range: range)

        case .deleteLastWord:
            result = handleDeleteLastWord(in: text, range: range)

        case .deleteLastSentence:
            result = handleDeleteLastSentence(in: text, range: range)
        }

        return result
    }

    private func handleInsertText(in text: String, range: Range<String.Index>, replacement: String) -> String {
        var result = text

        result.replaceSubrange(range, with: replacement)

        let insertionIndex = result.index(result.startIndex, offsetBy: result.distance(from: result.startIndex, to: range.lowerBound) + replacement.count)

        if insertionIndex < result.endIndex {
            let nextChar = result[insertionIndex]
            if nextChar == " " {
                return result
            }
        }

        return result
    }

    private func handleNewLine(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.replaceSubrange(range, with: "\n")

        let insertionIndex = result.index(result.startIndex, offsetBy: result.distance(from: result.startIndex, to: range.lowerBound) + 1)
        if insertionIndex < result.endIndex {
            let nextChar = result[insertionIndex]
            if nextChar == " " {
                let spaceRange = insertionIndex..<result.index(after: insertionIndex)
                result.replaceSubrange(spaceRange, with: "")
            }
        }

        return result
    }

    private func handleNewParagraph(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.replaceSubrange(range, with: "\n\n")

        let insertionIndex = result.index(result.startIndex, offsetBy: result.distance(from: result.startIndex, to: range.lowerBound) + 2)
        if insertionIndex < result.endIndex {
            let nextChar = result[insertionIndex]
            if nextChar == " " {
                let spaceRange = insertionIndex..<result.index(after: insertionIndex)
                result.replaceSubrange(spaceRange, with: "")
            }
        }

        return result
    }

    private func handleCapitalizeNext(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.removeSubrange(range)

        let removalOffset = result.distance(from: result.startIndex, to: range.lowerBound)
        var searchIndex = result.index(result.startIndex, offsetBy: removalOffset)

        if searchIndex < result.endIndex && result[searchIndex] == " " {
            searchIndex = result.index(after: searchIndex)
        }

        if searchIndex < result.endIndex {
            let wordEnd = result[searchIndex...].firstIndex(where: { $0.isWhitespace || $0.isPunctuation }) ?? result.endIndex
            let wordRange = searchIndex..<wordEnd

            if !wordRange.isEmpty {
                let word = String(result[wordRange])
                let capitalized = word.prefix(1).uppercased() + word.dropFirst()
                result.replaceSubrange(wordRange, with: capitalized)
            }
        }

        return result
    }

    private func handleUppercaseNext(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.removeSubrange(range)

        let removalOffset = result.distance(from: result.startIndex, to: range.lowerBound)
        var searchIndex = result.index(result.startIndex, offsetBy: removalOffset)

        if searchIndex < result.endIndex && result[searchIndex] == " " {
            searchIndex = result.index(after: searchIndex)
        }

        if searchIndex < result.endIndex {
            let wordEnd = result[searchIndex...].firstIndex(where: { $0.isWhitespace || $0.isPunctuation }) ?? result.endIndex
            let wordRange = searchIndex..<wordEnd

            if !wordRange.isEmpty {
                let word = String(result[wordRange])
                result.replaceSubrange(wordRange, with: word.uppercased())
            }
        }

        return result
    }

    private func handleLowercaseNext(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.removeSubrange(range)

        let removalOffset = result.distance(from: result.startIndex, to: range.lowerBound)
        var searchIndex = result.index(result.startIndex, offsetBy: removalOffset)

        if searchIndex < result.endIndex && result[searchIndex] == " " {
            searchIndex = result.index(after: searchIndex)
        }

        if searchIndex < result.endIndex {
            let wordEnd = result[searchIndex...].firstIndex(where: { $0.isWhitespace || $0.isPunctuation }) ?? result.endIndex
            let wordRange = searchIndex..<wordEnd

            if !wordRange.isEmpty {
                let word = String(result[wordRange])
                result.replaceSubrange(wordRange, with: word.lowercased())
            }
        }

        return result
    }

    private func handleDeleteLastWord(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.removeSubrange(range)

        let removalOffset = result.distance(from: result.startIndex, to: range.lowerBound)
        let searchEndIndex = result.index(result.startIndex, offsetBy: removalOffset)

        guard searchEndIndex > result.startIndex else { return result }

        let prefix = result[..<searchEndIndex]
        var workingText = String(prefix).trimmingCharacters(in: .whitespaces)

        if let lastSpaceIndex = workingText.lastIndex(where: { $0.isWhitespace }) {
            workingText = String(workingText[..<lastSpaceIndex])
        } else {
            workingText = ""
        }

        let suffix = result[searchEndIndex...]
        result = workingText + String(suffix)

        return result
    }

    private func handleDeleteLastSentence(in text: String, range: Range<String.Index>) -> String {
        var result = text

        result.removeSubrange(range)

        let removalOffset = result.distance(from: result.startIndex, to: range.lowerBound)
        let searchEndIndex = result.index(result.startIndex, offsetBy: removalOffset)

        guard searchEndIndex > result.startIndex else { return result }

        let prefix = result[..<searchEndIndex]
        var workingText = String(prefix).trimmingCharacters(in: .whitespaces)

        let sentenceEnders = CharacterSet(charactersIn: ".!?")
        if let lastSentenceIndex = workingText.unicodeScalars.lastIndex(where: { sentenceEnders.contains($0) }) {
            workingText = String(workingText[...lastSentenceIndex])
        } else {
            workingText = ""
        }

        let suffix = result[searchEndIndex...]
        result = workingText + String(suffix)

        return result
    }
}

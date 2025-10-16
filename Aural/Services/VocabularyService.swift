import Foundation

final class VocabularyService {
    private let repository = VocabularyRepository()
    private var vocabulary: CustomVocabulary

    init() {
        self.vocabulary = repository.load()
    }

    func reload() {
        self.vocabulary = repository.load()
    }

    func applyReplacements(to text: String) -> String {
        guard vocabulary.isEnabled else { return text }

        var result = text

        for entry in vocabulary.entries {
            if entry.caseSensitive {
                result = result.replacingOccurrences(
                    of: entry.source,
                    with: entry.replacement
                )
            } else {
                result = result.replacingOccurrences(
                    of: entry.source,
                    with: entry.replacement,
                    options: .caseInsensitive
                )
            }
        }

        return result
    }

    func applyWordBoundaryReplacements(to text: String) -> String {
        guard vocabulary.isEnabled else { return text }

        var result = text

        for entry in vocabulary.entries {
            let pattern: String
            if entry.caseSensitive {
                pattern = "\\b\(NSRegularExpression.escapedPattern(for: entry.source))\\b"
            } else {
                pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: entry.source))\\b"
            }

            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                continue
            }

            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: range,
                withTemplate: entry.replacement
            )
        }

        return result
    }
}

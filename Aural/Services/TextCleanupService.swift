import Foundation

final class TextCleanupService {
  private let fillerRepository: FillerWordsRepository

  init(fillerRepository: FillerWordsRepository = FillerWordsRepository()) {
    self.fillerRepository = fillerRepository
  }

  private var isStutterRemovalEnabled: Bool {
    UserDefaults.standard.bool(forKey: UserDefaultsKeys.removeStuttering)
  }

  func cleanup(_ text: String) -> String {
    var result = text

    if isStutterRemovalEnabled {
      result = removeStuttering(from: result)
    }

    result = removeFillerWords(from: result)
    result = normalizeWhitespace(result)

    return result
  }

  func removeFillerWords(from text: String) -> String {
    let config = fillerRepository.load()
    guard config.isEnabled else { return text }

    var result = text
    for filler in config.words {
      let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: filler))\\b[,]?"
      guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
      let range = NSRange(result.startIndex..., in: result)
      result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "")
    }
    return result
  }

  func removeStuttering(from text: String) -> String {
    let pattern = "\\b(\\w+)(\\s+\\1)+\\b"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
      return text
    }
    let range = NSRange(text.startIndex..., in: text)
    return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
  }

  private func normalizeWhitespace(_ text: String) -> String {
    text
      .replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
      .replacingOccurrences(of: "\\s+([.,!?;:])", with: "$1", options: .regularExpression)
      .trimmingCharacters(in: .whitespaces)
  }
}

import Foundation

struct FillerWordsConfiguration: Codable {
  var isEnabled: Bool
  var words: [String]

  static let defaultFillerWords = [
    "um", "umm", "uh", "uhh", "uhm", "er", "err", "ah", "ahh",
    "hmm", "hm", "mhm", "uh-huh", "mm-hmm"
  ]

  init(isEnabled: Bool = false, words: [String]? = nil) {
    self.isEnabled = isEnabled
    self.words = words ?? Self.defaultFillerWords
  }

  mutating func resetToDefaults() {
    words = Self.defaultFillerWords
  }
}

final class FillerWordsRepository {
  private let key = UserDefaultsKeys.fillerWordsConfiguration
  private let userDefaults: UserDefaults

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  func save(_ config: FillerWordsConfiguration) {
    if let encoded = try? JSONEncoder().encode(config) {
      userDefaults.set(encoded, forKey: key)
    }
  }

  func load() -> FillerWordsConfiguration {
    guard let data = userDefaults.data(forKey: key),
          let config = try? JSONDecoder().decode(FillerWordsConfiguration.self, from: data) else {
      return FillerWordsConfiguration()
    }
    return config
  }
}

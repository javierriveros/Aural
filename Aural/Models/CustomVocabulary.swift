import Foundation

// MARK: - Vocabulary Entry

struct VocabularyEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var source: String
    var replacement: String
    var caseSensitive: Bool
    var category: VocabularyCategory

    init(id: UUID = UUID(), source: String, replacement: String, caseSensitive: Bool = false, category: VocabularyCategory = .custom) {
        self.id = id
        self.source = source
        self.replacement = replacement
        self.caseSensitive = caseSensitive
        self.category = category
    }
}

// MARK: - Vocabulary Category

enum VocabularyCategory: String, Codable, CaseIterable, Identifiable {
    case custom = "Custom"
    case technical = "Technical"
    case names = "Names"
    case acronyms = "Acronyms"
    case phrases = "Phrases"

    var id: String { rawValue }
}

// MARK: - Custom Vocabulary

struct CustomVocabulary: Codable {
    var entries: [VocabularyEntry]
    var isEnabled: Bool

    init(entries: [VocabularyEntry] = [], isEnabled: Bool = true) {
        self.entries = entries
        self.isEnabled = isEnabled
    }

    mutating func add(_ entry: VocabularyEntry) {
        entries.append(entry)
    }

    mutating func remove(_ entry: VocabularyEntry) {
        entries.removeAll { $0.id == entry.id }
    }

    mutating func update(_ entry: VocabularyEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        }
    }

    func entries(for category: VocabularyCategory) -> [VocabularyEntry] {
        return entries.filter { $0.category == category }
    }
}

// MARK: - Vocabulary Repository

final class VocabularyRepository {
    private let key = UserDefaultsKeys.customVocabulary

    func save(_ vocabulary: CustomVocabulary) {
        if let encoded = try? JSONEncoder().encode(vocabulary) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func load() -> CustomVocabulary {
        guard let data = UserDefaults.standard.data(forKey: key),
              let vocabulary = try? JSONDecoder().decode(CustomVocabulary.self, from: data) else {
            return CustomVocabulary()
        }
        return vocabulary
    }

    func exportToJSON() -> Data? {
        let vocabulary = load()
        return try? JSONEncoder().encode(vocabulary)
    }

    func importFromJSON(_ data: Data) -> Bool {
        guard let vocabulary = try? JSONDecoder().decode(CustomVocabulary.self, from: data) else {
            return false
        }
        save(vocabulary)
        return true
    }
}

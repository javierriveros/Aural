@testable import Aural
import XCTest

final class VocabularyServiceTests: XCTestCase {
    var service: VocabularyService!
    var repository: VocabularyRepository!

    override func setUp() {
        super.setUp()
        repository = VocabularyRepository()
        // Clear any existing vocabulary for testing
        let emptyVocab = CustomVocabulary(entries: [], isEnabled: true)
        repository.save(emptyVocab)
        service = VocabularyService()
    }

    override func tearDown() {
        service = nil
        repository = nil
        super.tearDown()
    }

    func testApplyReplacementsCaseInsensitive() {
        let entry = VocabularyEntry(source: "apple", replacement: "orange", caseSensitive: false)
        var vocab = CustomVocabulary(entries: [entry], isEnabled: true)
        repository.save(vocab)
        service.reload()

        let input = "I have an Apple and an apple."
        let expected = "I have an orange and an orange."
        XCTAssertEqual(service.applyReplacements(to: input), expected)
    }

    func testApplyReplacementsCaseSensitive() {
        let entry = VocabularyEntry(source: "apple", replacement: "orange", caseSensitive: true)
        var vocab = CustomVocabulary(entries: [entry], isEnabled: true)
        repository.save(vocab)
        service.reload()

        let input = "I have an Apple and an apple."
        let expected = "I have an Apple and an orange."
        XCTAssertEqual(service.applyReplacements(to: input), expected)
    }

    func testApplyWordBoundaryReplacements() {
        let entry = VocabularyEntry(source: "ice", replacement: "fire", caseSensitive: false)
        var vocab = CustomVocabulary(entries: [entry], isEnabled: true)
        repository.save(vocab)
        service.reload()

        let input = "The ice is nice, but solstice is not ice."
        let expected = "The fire is nice, but solstice is not fire."
        XCTAssertEqual(service.applyWordBoundaryReplacements(to: input), expected)
    }

    func testDisabledVocabularyDoesNotApplyReplacements() {
        let entry = VocabularyEntry(source: "apple", replacement: "orange", caseSensitive: false)
        var vocab = CustomVocabulary(entries: [entry], isEnabled: false)
        repository.save(vocab)
        service.reload()

        let input = "I have an apple."
        XCTAssertEqual(service.applyReplacements(to: input), input)
        XCTAssertEqual(service.applyWordBoundaryReplacements(to: input), input)
    }
}

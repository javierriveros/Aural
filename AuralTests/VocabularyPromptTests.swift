@testable import Aural
import XCTest

final class VocabularyPromptTests: XCTestCase {
    private func entries(_ terms: [String]) -> [VocabularyEntry] {
        terms.map { VocabularyEntry(source: "src", replacement: $0) }
    }

    func testJoinsAndDedupesReplacements() {
        let prompt = VocabularyService.transcriptionPrompt(from: entries(["term-1", "Acme-Widget", "TERM-1", " "]))
        XCTAssertEqual(prompt, "term-1, Acme-Widget")
    }

    func testCapsLength() {
        let prompt = VocabularyService.transcriptionPrompt(from: entries(["term-1", "term-2", "term-3"]), maxLength: 14)
        XCTAssertEqual(prompt, "term-1, term-2")
    }

    func testEmpty() {
        XCTAssertEqual(VocabularyService.transcriptionPrompt(from: []), "")
    }
}

final class PromptEchoTests: XCTestCase {
    func testEqualAndPrefixAreEchoes() {
        XCTAssertTrue(CloudTranscriptionService.isPromptEcho("Term-1, term-2.", prompt: "term-1, term-2"))
        XCTAssertTrue(CloudTranscriptionService.isPromptEcho("term-1, term-2, term", prompt: "term-1, term-2, term-3"))
    }

    func testSingleTermDictationIsNotEcho() {
        XCTAssertFalse(CloudTranscriptionService.isPromptEcho("Term-1.", prompt: "term-1, term-2"))
    }

    func testUnrelatedTextIsNotEcho() {
        XCTAssertFalse(CloudTranscriptionService.isPromptEcho("hello there", prompt: "term-1, term-2"))
    }

    func testEmptyPromptIsNotEcho() {
        XCTAssertFalse(CloudTranscriptionService.isPromptEcho("hello", prompt: ""))
        XCTAssertFalse(CloudTranscriptionService.isPromptEcho("", prompt: ""))
    }
}

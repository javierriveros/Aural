@testable import Aural
import XCTest

final class TextInjectionServiceTests: XCTestCase {
    private func adjust(_ text: String, _ preceding: String?) -> String {
        TextInjectionService.adjust(text, precedingText: preceding)
    }

    func testUnknownContextIsUnchanged() {
        XCTAssertEqual(adjust("Hello there", nil), "Hello there")
    }

    func testEmptyFieldCapitalizesWithoutSpace() {
        XCTAssertEqual(adjust("hello there", ""), "Hello there")
    }

    func testAfterNewlineCapitalizesWithoutSpace() {
        XCTAssertEqual(adjust("hello", "line one\n"), "Hello")
    }

    func testAfterWordAddsSpaceAndLeavesCaseUnchanged() {
        XCTAssertEqual(adjust("then we left", "and so"), " then we left")
        XCTAssertEqual(adjust("Paris is nice", "so"), " Paris is nice")
    }

    func testAfterSentenceEndAddsSpaceAndCapitalizes() {
        XCTAssertEqual(adjust("then we left", "It ended."), " Then we left")
        XCTAssertEqual(adjust("then", "Really?"), " Then")
        XCTAssertEqual(adjust("then", "Wow!"), " Then")
    }

    func testSentenceEndFollowedBySpaceCapitalizesWithoutExtraSpace() {
        XCTAssertEqual(adjust("then", "It ended. "), "Then")
    }

    func testLeadingPunctuationGetsNoSpace() {
        for mark in [".", ",", "!", "?", ";", ":", ")"] {
            XCTAssertEqual(adjust("\(mark) ok", "word"), "\(mark) ok")
        }
    }

    func testNoSpaceAfterOpeningBracket() {
        XCTAssertEqual(adjust("note", "see ("), "note")
    }

    func testLeadingWhitespaceIsUnchanged() {
        XCTAssertEqual(adjust("\nnew line", "word"), "\nnew line")
        XCTAssertEqual(adjust(" hi", "It ended."), " hi")
    }

    func testEmptyTextIsUnchanged() {
        XCTAssertEqual(adjust("", "word"), "")
    }
}

@testable import Aural
import XCTest

final class VoiceCommandProcessorTests: XCTestCase {
    var processor: VoiceCommandProcessor!

    override func setUp() {
        super.setUp()
        processor = VoiceCommandProcessor()
        UserDefaults.standard.set(true, forKey: UserDefaultsKeys.voiceCommandsEnabled)
    }

    override func tearDown() {
        processor = nil
        super.tearDown()
    }

    func testCapitalizeNext() {
        let input = "hello cap world"
        let expected = "hello World"
        XCTAssertEqual(processor.process(input), expected)
    }

    func testUppercaseNext() {
        let input = "this is uppercase urgent"
        let expected = "this is URGENT"
        XCTAssertEqual(processor.process(input), expected)
    }

    func testLowercaseNext() {
        let input = "MAKE IT lowercase SMALL"
        let expected = "MAKE IT small"
        XCTAssertEqual(processor.process(input), expected)
    }

    func testDeleteLastWord() {
        let input = "keep this but scratch that"
        let expected = "keep this"
        XCTAssertEqual(processor.process(input).trimmingCharacters(in: .whitespaces), expected)
    }

    func testDeleteLastSentence() {
        let input = "First sentence. Second sentence. scratch sentence"
        let expected = "First sentence."
        XCTAssertEqual(processor.process(input).trimmingCharacters(in: .whitespaces), expected)
    }

    func testNewLine() {
        let input = "line one new line line two"
        let expected = "line one\nline two"
        XCTAssertEqual(processor.process(input), expected)
    }

    func testNewParagraph() {
        let input = "para one new paragraph para two"
        let expected = "para one\n\npara two"
        XCTAssertEqual(processor.process(input), expected)
    }

    func testCommandChaining() {
        let input = "hello new line cap world"
        let expected = "hello\nWorld"
        XCTAssertEqual(processor.process(input), expected)
    }

    func testDisabledCommands() {
        UserDefaults.standard.set(false, forKey: UserDefaultsKeys.voiceCommandsEnabled)
        let input = "hello cap world"
        XCTAssertEqual(processor.process(input), input)
    }
}

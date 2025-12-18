@testable import Aural
import XCTest

final class TranscriptionTests: XCTestCase {
    func testTranscriptionInitialization() {
        let text = "Test transcription"
        let duration: TimeInterval = 10.5
        let cost = 0.05
        let providerType = "cloud"
        let providerName = "OpenAI"

        let transcription = Transcription(
            text: text,
            duration: duration,
            cost: cost,
            providerType: providerType,
            providerName: providerName
        )

        XCTAssertEqual(transcription.text, text)
        XCTAssertEqual(transcription.duration, duration)
        XCTAssertEqual(transcription.cost, cost)
        XCTAssertEqual(transcription.providerType, providerType)
        XCTAssertEqual(transcription.providerName, providerName)
        XCTAssertNotNil(transcription.id)
        XCTAssertNotNil(transcription.timestamp)
    }

    func testTranscriptionDefaultValues() {
        let text = "Test transcription"
        let duration: TimeInterval = 5.0

        let transcription = Transcription(text: text, duration: duration)

        XCTAssertEqual(transcription.cost, 0.0)
        XCTAssertNil(transcription.providerType)
        XCTAssertNil(transcription.providerName)
    }
}

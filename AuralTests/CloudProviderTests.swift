@testable import Aural
import XCTest

final class CloudProviderTests: XCTestCase {
    func testOpenAIEndpoints() {
        let provider = CloudProvider.openai
        XCTAssertEqual(provider.apiEndpoint.absoluteString, "https://api.openai.com/v1/audio/transcriptions")
        XCTAssertEqual(provider.defaultModel, "whisper-1")
    }

    func testGroqEndpoints() {
        let provider = CloudProvider.groq
        XCTAssertEqual(provider.apiEndpoint.absoluteString, "https://api.groq.com/openai/v1/audio/transcriptions")
        XCTAssertEqual(provider.defaultModel, "whisper-large-v3-turbo")
    }
}

@testable import Aural
import AVFoundation
import XCTest

final class AudioFormatConverterTests: XCTestCase {
    var converter: AudioFormatConverter!
    var tempFiles: [URL] = []

    override func setUp() {
        super.setUp()
        converter = AudioFormatConverter()
    }

    override func tearDown() {
        converter = nil
        // Cleanup temp files
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
        super.tearDown()
    }

    func testConvertToPCM() async throws {
        // Create a 1-second dummy audio file
        let sourceURL = try AudioTestHelper.createTemporaryAudioFile(duration: 1.0)
        tempFiles.append(sourceURL)

        // Convert it
        let outputURL = try await converter.convertToPCM(url: sourceURL)
        tempFiles.append(outputURL)

        // Verify output exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Check format
        let asset = AVURLAsset(url: outputURL)
        let track = try await asset.loadTracks(withMediaType: .audio).first
        XCTAssertNotNil(track)

        // Needed for proper format checking on some platforms/tests
        let formatDescriptions = try await track?.load(.formatDescriptions)
        guard let formatDesc = formatDescriptions?.first else {
            XCTFail("Could not load format description")
            return
        }

        guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) else {
            XCTFail("Could not get basic description")
            return
        }

        let sampleRate = basicDescription.pointee.mSampleRate
        let channels = basicDescription.pointee.mChannelsPerFrame
        let formatID = basicDescription.pointee.mFormatID

        XCTAssertEqual(sampleRate, 16000.0, accuracy: 0.1)
        XCTAssertEqual(channels, 1)
        XCTAssertEqual(formatID, kAudioFormatLinearPCM)
    }

    func testInvalidFile() async {
        let invalidURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        do {
            _ = try await converter.convertToPCM(url: invalidURL)
            XCTFail("Should have thrown error")
        } catch {
            // Expected error
        }
    }
}

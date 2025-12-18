@testable import Aural
import AVFoundation
import XCTest

final class AudioProcessorTests: XCTestCase {
    var processor: AudioProcessor!
    var tempFiles: [URL] = []

    override func setUp() {
        super.setUp()
        processor = AudioProcessor()
    }

    override func tearDown() {
        processor = nil
        for url in tempFiles {
            try? FileManager.default.removeItem(at: url)
        }
        tempFiles.removeAll()
        super.tearDown()
    }

    func testEstimateCostSavings() {
        // Price per minute is $0.006
        let duration: TimeInterval = 60.0 // 1 minute
        let speedMultiplier: Float = 2.0 // Half duration

        let originalCost = 0.006
        let newDuration = 30.0
        let newCost = (newDuration / 60.0) * 0.006 // 0.003
        let expectedSavings = originalCost - newCost // 0.003

        let savings = processor.estimateCostSavings(duration: duration, speedMultiplier: speedMultiplier)

        XCTAssertEqual(savings, expectedSavings, accuracy: 0.0001)
    }

    func testSpeedUpAudio() async throws {
        // Create 1-second audio file
        let sourceURL = try AudioTestHelper.createTemporaryAudioFile(duration: 2.0)
        tempFiles.append(sourceURL)

        // Speed up by 2x
        let outputURL = try await processor.speedUpAudio(url: sourceURL, speedMultiplier: 2.0)
        tempFiles.append(outputURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))

        // Check duration
        let asset = AVURLAsset(url: outputURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        // Duration should be approx 1.0 second (2.0 / 2.0)
        XCTAssertEqual(durationSeconds, 1.0, accuracy: 0.1)
    }

    func testSpeedUpAudioNoChange() async throws {
        let sourceURL = try AudioTestHelper.createTemporaryAudioFile(duration: 1.0)
        tempFiles.append(sourceURL)

        let outputURL = try await processor.speedUpAudio(url: sourceURL, speedMultiplier: 1.0)

        // Should return original URL
        XCTAssertEqual(outputURL, sourceURL)
    }
}

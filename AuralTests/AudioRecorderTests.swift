@testable import Aural
import AVFoundation
import XCTest

final class AudioRecorderTests: XCTestCase {
    func testStereoInputIsDownmixedAndWritableToMonoFile() throws {
        let sampleRate = 48000.0
        let frames: AVAudioFrameCount = 48000
        let stereo = try XCTUnwrap(AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2))
        let monoFormat = try XCTUnwrap(AVAudioFormat(
            commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false
        ))
        let converter = try XCTUnwrap(AVAudioConverter(from: stereo, to: monoFormat))

        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: stereo, frameCapacity: frames))
        buffer.frameLength = frames
        let channels = try XCTUnwrap(buffer.floatChannelData)
        for frame in 0..<Int(frames) {
            let sample = Float(sin(2 * Double.pi * 440 * Double(frame) / sampleRate)) * 0.5
            channels[0][frame] = sample
            channels[1][frame] = sample
        }

        let mono = try XCTUnwrap(AudioRecorder.monoBuffer(from: buffer, using: converter))
        XCTAssertEqual(mono.format.channelCount, 1)
        XCTAssertEqual(mono.frameLength, frames)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("downmix-test-\(UUID().uuidString).m4a")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let file = try AVAudioFile(forWriting: url, settings: AudioRecorder.fileSettings)
            try file.write(from: mono)
        }

        let readBack = try AVAudioFile(forReading: url)
        XCTAssertGreaterThan(readBack.length, 0)
    }
}

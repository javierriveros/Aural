import AVFoundation
import Foundation

enum AudioTestHelper {
    static func createTemporaryAudioFile(duration: TimeInterval = 1.0) throws -> URL {
        let temporaryDirectoryURL = FileManager.default.temporaryDirectory
        let audioFileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        let audioFile = try AVAudioFile(forWriting: audioFileURL, settings: settings)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioTestHelper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PCM buffer"])
        }

        buffer.frameLength = frameCount

        // Fill with silence
        if let channelData = buffer.int16ChannelData {
            let channelPointer = channelData[0]
            for index in 0..<Int(frameCount) {
                channelPointer[index] = 0
            }
        }

        try audioFile.write(from: buffer)
        return audioFileURL
    }
}

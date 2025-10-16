import Foundation
import AVFoundation

final class AudioProcessor {
    enum ProcessingError: LocalizedError {
        case fileNotFound
        case invalidAudioFile
        case processingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Audio file not found"
            case .invalidAudioFile:
                return "Invalid audio file format"
            case .processingFailed(let error):
                return "Audio processing failed: \(error.localizedDescription)"
            }
        }
    }

    func speedUpAudio(url: URL, speedMultiplier: Float) async throws -> URL {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ProcessingError.fileNotFound
        }

        guard speedMultiplier > 0 && speedMultiplier <= 2.0 else {
            return url
        }

        if speedMultiplier == 1.0 {
            return url
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat

            let engine = AVAudioEngine()
            let playerNode = AVAudioPlayerNode()
            let timePitch = AVAudioUnitTimePitch()

            engine.attach(playerNode)
            engine.attach(timePitch)

            engine.connect(playerNode, to: timePitch, format: format)
            engine.connect(timePitch, to: engine.mainMixerNode, format: format)

            timePitch.rate = speedMultiplier

            let outputFile = try AVAudioFile(
                forWriting: outputURL,
                settings: audioFile.fileFormat.settings
            )

            engine.mainMixerNode.installTap(
                onBus: 0,
                bufferSize: 4096,
                format: format
            ) { buffer, _ in
                try? outputFile.write(from: buffer)
            }

            try engine.start()
            await playerNode.scheduleFile(audioFile, at: nil)
            playerNode.play()

            let duration = Double(audioFile.length) / format.sampleRate / Double(speedMultiplier)
            try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

            engine.mainMixerNode.removeTap(onBus: 0)
            engine.stop()

            return outputURL
        } catch {
            throw ProcessingError.processingFailed(error)
        }
    }

    func estimateCostSavings(duration: TimeInterval, speedMultiplier: Float) -> Double {
        let pricePerMinute = 0.006
        let originalCost = (duration / 60.0) * pricePerMinute
        let newDuration = duration / Double(speedMultiplier)
        let newCost = (newDuration / 60.0) * pricePerMinute
        return originalCost - newCost
    }
}

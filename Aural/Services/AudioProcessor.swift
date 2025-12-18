import AVFoundation
import Foundation

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

protocol AudioProcessorProtocol: AnyObject {
    func speedUpAudio(url: URL, speedMultiplier: Float) async throws -> URL
    func estimateCostSavings(duration: TimeInterval, speedMultiplier: Float) -> Double
}

final class AudioProcessor: AudioProcessorProtocol {

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
            let asset = AVURLAsset(url: url)

            let audioTracks = try await asset.loadTracks(withMediaType: .audio)
            guard let assetTrack = audioTracks.first else {
                throw ProcessingError.invalidAudioFile
            }

            let composition = AVMutableComposition()
            guard let compositionTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else {
                throw ProcessingError.processingFailed(NSError(domain: "AudioProcessor", code: -1))
            }

            let duration = try await asset.load(.duration)

            try compositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                of: assetTrack,
                at: .zero
            )

            compositionTrack.scaleTimeRange(
                CMTimeRange(start: .zero, duration: duration),
                toDuration: CMTimeMultiplyByFloat64(duration, multiplier: Float64(1.0 / speedMultiplier))
            )

            guard let exportSession = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetAppleM4A
            ) else {
                throw ProcessingError.processingFailed(NSError(domain: "AudioProcessor", code: -2))
            }

            exportSession.outputURL = outputURL
            exportSession.outputFileType = .m4a

            do {
                try await exportSession.export(to: outputURL, as: .m4a)
                return outputURL
            } catch {
                try? FileManager.default.removeItem(at: outputURL)
                throw ProcessingError.processingFailed(error)
            }
        } catch {
            try? FileManager.default.removeItem(at: outputURL)
            throw error
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

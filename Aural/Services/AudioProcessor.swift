import AVFoundation
import Foundation

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
            return try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let asset = AVURLAsset(url: url)

                        guard let assetTrack = asset.tracks(withMediaType: .audio).first else {
                            continuation.resume(throwing: ProcessingError.invalidAudioFile)
                            return
                        }

                        let composition = AVMutableComposition()
                        guard let compositionTrack = composition.addMutableTrack(
                            withMediaType: .audio,
                            preferredTrackID: kCMPersistentTrackID_Invalid
                        ) else {
                            continuation.resume(throwing: ProcessingError.processingFailed(NSError(domain: "AudioProcessor", code: -1)))
                            return
                        }

                        try compositionTrack.insertTimeRange(
                            CMTimeRange(start: .zero, duration: asset.duration),
                            of: assetTrack,
                            at: .zero
                        )

                        compositionTrack.scaleTimeRange(
                            CMTimeRange(start: .zero, duration: asset.duration),
                            toDuration: CMTimeMultiplyByFloat64(asset.duration, multiplier: Float64(1.0 / speedMultiplier))
                        )

                        guard let exportSession = AVAssetExportSession(
                            asset: composition,
                            presetName: AVAssetExportPresetAppleM4A
                        ) else {
                            continuation.resume(throwing: ProcessingError.processingFailed(NSError(domain: "AudioProcessor", code: -2)))
                            return
                        }

                        exportSession.outputURL = outputURL
                        exportSession.outputFileType = .m4a

                        exportSession.exportAsynchronously {
                            switch exportSession.status {
                            case .completed:
                                continuation.resume(returning: outputURL)
                            case .failed, .cancelled:
                                try? FileManager.default.removeItem(at: outputURL)

                                if let error = exportSession.error {
                                    continuation.resume(throwing: ProcessingError.processingFailed(error))
                                } else {
                                    continuation.resume(throwing: ProcessingError.processingFailed(NSError(domain: "AudioProcessor", code: -3)))
                                }
                            default:
                                try? FileManager.default.removeItem(at: outputURL)
                                continuation.resume(throwing: ProcessingError.processingFailed(NSError(domain: "AudioProcessor", code: -5)))
                            }
                        }
                    } catch {
                        continuation.resume(throwing: ProcessingError.processingFailed(error))
                    }
                }
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

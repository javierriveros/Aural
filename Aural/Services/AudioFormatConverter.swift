import AVFoundation
import Foundation

/// Converts audio files to the format required by local transcription models (16kHz Mono PCM WAV)
final class AudioFormatConverter {
    enum ConverterError: LocalizedError {
        case assetLoadFailed
        case noAudioTrack
        case readerStartFailed
        case writerStartFailed
        case exportFailed(Error)
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .assetLoadFailed:
                return "Failed to load audio asset"
            case .noAudioTrack:
                return "No audio track found in file"
            case .readerStartFailed:
                return "Failed to start reading audio file"
            case .writerStartFailed:
                return "Failed to start writing audio file"
            case .exportFailed(let error):
                return "Audio conversion failed: \(error.localizedDescription)"
            case .invalidFormat:
                return "Invalid audio format for conversion"
            }
        }
    }

    /// Converts input audio file to 16kHz Mono PCM WAV
    /// - Parameter url: Source audio file URL
    /// - Returns: URL to converted WAV file in temporary directory
    func convertToPCM(url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)

        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard tracks.first != nil else {
            throw ConverterError.noAudioTrack
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        // Define target format: 16kHz, 1-channel (mono), 16-bit PCM
        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: LocalModelConstants.whisperSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw ConverterError.invalidFormat
        }

        return try await performConversion(asset: asset, outputURL: outputURL, targetFormat: targetFormat)
    }

    private func performConversion(asset: AVAsset, outputURL: URL, targetFormat: AVAudioFormat) async throws -> URL {
        let reader = try AVAssetReader(asset: asset)
        let tracks = try await asset.loadTracks(withMediaType: .audio)

        guard let assetTrack = tracks.first else {
            throw ConverterError.noAudioTrack
        }

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: targetFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let readerSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: readerSettings)
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .wav)
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
        writer.add(writerInput)

        guard reader.startReading() else {
            throw ConverterError.readerStartFailed
        }

        guard writer.startWriting() else {
            throw ConverterError.writerStartFailed
        }

        writer.startSession(atSourceTime: .zero)

        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "com.aural.audio.conversion", qos: .userInitiated)

            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if reader.status == .failed {
                        writerInput.markAsFinished()
                        writer.cancelWriting()
                        continuation.resume(throwing: ConverterError.assetLoadFailed)
                        return
                    }

                    if let buffer = readerOutput.copyNextSampleBuffer() {
                        if !writerInput.append(buffer) {
                            writerInput.markAsFinished()
                            writer.cancelWriting()
                            continuation.resume(throwing: ConverterError.exportFailed(writer.error ?? NSError(domain: "AudioConverter", code: -1)))
                            return
                        }
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                continuation.resume(returning: outputURL)
                            } else {
                                continuation.resume(throwing: ConverterError.exportFailed(
                                    writer.error ?? NSError(domain: "AudioConverter", code: -1)
                                ))
                            }
                        }
                        return
                    }
                }
            }
        }
    }
}

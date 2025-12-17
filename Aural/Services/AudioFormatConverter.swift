import AVFoundation
import Foundation

final class AudioFormatConverter {
    enum ConverterError: LocalizedError {
        case assetLoadFailed
        case exportFailed(Error)
        case invalidFormat
        
        var errorDescription: String? {
            switch self {
            case .assetLoadFailed: return "Failed to load audio asset"
            case .exportFailed(let error): return "Audio conversion failed: \(error.localizedDescription)"
            case .invalidFormat: return "Invalid audio format for conversion"
            }
        }
    }
    
    /// Converts input audio file to 16kHz Mono PCM WAV
    func convertToPCM(url: URL) async throws -> URL {
        let asset = AVURLAsset(url: url)
        
        // Load track and duration
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = tracks.first else {
            throw ConverterError.assetLoadFailed
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        
        // Define target format: 16kHz, 1-channel (mono), 16-bit PCM
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: LocalModelConstants.whisperSampleRate,
            channels: 1,
            interleaved: false
        )!
        
        // Use AVAudioFile and AVAudioEngine/AVAudioConverter for high quality resampling
        // Simplified approach using AVAssetReader/Writer for format conversion
        return try await performConversion(asset: asset, outputURL: outputURL, targetFormat: targetFormat)
    }
    
    private func performConversion(asset: AVAsset, outputURL: URL, targetFormat: AVAudioFormat) async throws -> URL {
        // Implementation using AVAssetReader and AVAssetWriter for robust conversion
        let reader = try AVAssetReader(asset: asset)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        let assetTrack = tracks.first!
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: targetFormat.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: assetTrack, outputSettings: nil)
        reader.add(readerOutput)
        
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .wav)
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
        writer.add(writerInput)
        
        reader.startReading()
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "audio.conversion.queue")
            
            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if let buffer = readerOutput.copyNextSampleBuffer() {
                        writerInput.append(buffer)
                    } else {
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                continuation.resume(returning: outputURL)
                            } else {
                                continuation.resume(throwing: ConverterError.exportFailed(writer.error ?? NSError(domain: "AudioConverter", code: -1)))
                            }
                        }
                        break
                    }
                }
            }
        }
    }
}

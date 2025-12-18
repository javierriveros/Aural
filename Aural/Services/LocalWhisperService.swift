import Foundation
import AVFoundation
#if canImport(SwiftWhisper)
import SwiftWhisper
#endif

// Note: SwiftWhisper integration requires adding the package to the Xcode project:
// https://github.com/exPHAT/SwiftWhisper.git
//
// Until SwiftWhisper is added, this service will throw an error indicating setup is required.

final class LocalWhisperService: TranscriptionProvider {
    private let modelDownloadManager: ModelDownloadManager
    private let audioConverter = AudioFormatConverter()
    private var whisper: Whisper?
    private var currentModelPath: URL?
    private var isInitializing = false
    
    init(modelDownloadManager: ModelDownloadManager) {
        self.modelDownloadManager = modelDownloadManager
    }
    
    var isAvailable: Bool {
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId),
              model.family == .whisper else {
            return false
        }
        
        // Check if model is downloaded
        guard modelDownloadManager.isModelDownloaded(model) else {
            return false
        }
        
        // SwiftWhisper package is not yet integrated
        // Return false until the dependency is properly set up
        #if canImport(SwiftWhisper)
        return true
        #else
        return false
        #endif
    }
    
    private func ensureInitialized() async throws -> Whisper {
        #if canImport(SwiftWhisper)
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId) else {
            throw LocalModelError.noModelSelected
        }
        
        let modelPath = modelDownloadManager.downloadPath(for: model)
        
        if let existing = whisper, currentModelPath == modelPath {
            return existing
        }
        
        while isInitializing {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        if let existing = whisper, currentModelPath == modelPath {
            return existing
        }
        
        isInitializing = true
        defer { isInitializing = false }
        
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw LocalModelError.modelNotDownloaded
        }
        
        let newWhisper = Whisper(fromFileURL: modelPath)
        self.whisper = newWhisper
        self.currentModelPath = modelPath
        return newWhisper
        #else
        throw LocalModelError.notImplemented
        #endif
    }
    
    func preload() async {
        _ = try? await ensureInitialized()
    }
    
    func transcribe(audioURL: URL) async throws -> String {
        guard let selectedId = UserDefaults.standard.string(forKey: UserDefaultsKeys.selectedModelId),
              let model = ModelRegistry.model(forId: selectedId) else {
            throw LocalModelError.noModelSelected
        }
        
        let modelPath = modelDownloadManager.downloadPath(for: model)
        guard FileManager.default.fileExists(atPath: modelPath.path) else {
            throw LocalModelError.modelNotDownloaded
        }
        
        // SwiftWhisper integration
        // To enable local Whisper transcription:
        // 1. Add SwiftWhisper package to Xcode: https://github.com/exPHAT/SwiftWhisper.git
        // 2. Import SwiftWhisper at the top of this file
        // 3. Implement the transcription logic below
        
        #if canImport(SwiftWhisper)
        let whisper = try await ensureInitialized()
        
        // Convert audio to 16kHz PCM WAV (required by Whisper)
        let pcmURL = try await audioConverter.convertToPCM(url: audioURL)
        defer { try? FileManager.default.removeItem(at: pcmURL) }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Read the audio file into a buffer
                let file = try AVAudioFile(forReading: pcmURL)
                guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false),
                      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
                    throw LocalModelError.audioConversionFailed
                }
                
                try file.read(into: buffer)
                
                guard let floatChannelData = buffer.floatChannelData else {
                    throw LocalModelError.audioConversionFailed
                }
                
                // Convert to [Float]
                let frameLength = Int(buffer.frameLength)
                let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
                
                whisper.transcribe(audioFrames: samples) { result in
                    switch result {
                    case .success(let segments):
                        let text = segments.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                        continuation.resume(returning: text)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
        #else
        throw LocalModelError.notImplemented
        #endif
    }
}

import AVFoundation
import Foundation
#if canImport(SwiftWhisper)
import SwiftWhisper
#endif

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
        
        guard modelDownloadManager.isModelDownloaded(model) else {
            return false
        }
        
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
        #if canImport(SwiftWhisper)
        let whisper = try await ensureInitialized()
        
        let pcmURL = try await audioConverter.convertToPCM(url: audioURL)
        defer { try? FileManager.default.removeItem(at: pcmURL) }
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let file = try AVAudioFile(forReading: pcmURL)
                guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: 1, interleaved: false),
                      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else {
                    throw LocalModelError.audioConversionFailed
                }
                
                try file.read(into: buffer)
                
                guard let floatChannelData = buffer.floatChannelData else {
                    throw LocalModelError.audioConversionFailed
                }
                
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

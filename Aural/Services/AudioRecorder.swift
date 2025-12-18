import AVFoundation
import Foundation

enum RecordingState: Equatable {
    case idle
    case recording
    case failed(Error)

    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

enum RecordingError: LocalizedError {
    case permissionDenied
    case recordingFailed
    case audioEngineFailure
    case audioWriteFailure(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .recordingFailed:
            return "Failed to start recording"
        case .audioEngineFailure:
            return "Audio engine initialization failed"
        case .audioWriteFailure(let error):
            return "Failed to write audio data: \(error.localizedDescription)"
        }
    }
}

protocol AudioRecorderProtocol: AnyObject {
    var state: RecordingState { get }
    var recordingDuration: TimeInterval { get }

    func setLevelMonitor(_ monitor: AudioLevelMonitor)
    func requestPermission() async -> Bool
    func startRecording() async throws -> URL
    func stopRecording() -> URL?
}

@Observable
final class AudioRecorder: AudioRecorderProtocol {

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    private weak var levelMonitor: AudioLevelMonitor?

    private(set) var state: RecordingState = .idle
    private(set) var recordingDuration: TimeInterval = 0
    private var timer: Timer?
    private var writeErrorCount = 0
    private let maxWriteErrors = 10

    init() {}

    func setLevelMonitor(_ monitor: AudioLevelMonitor) {
        self.levelMonitor = monitor
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() async throws -> URL {
        guard await requestPermission() else {
            state = .failed(RecordingError.permissionDenied)
            throw RecordingError.permissionDenied
        }

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        let documentsPath = FileManager.default.temporaryDirectory
        let audioFilename = documentsPath.appendingPathComponent("recording-\(UUID().uuidString).m4a")

        guard let audioFile = try? AVAudioFile(
            forWriting: audioFilename,
            settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        ) else {
            state = .failed(RecordingError.audioEngineFailure)
            throw RecordingError.audioEngineFailure
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            do {
                try audioFile.write(from: buffer)
                self.writeErrorCount = 0
            } catch {
                self.writeErrorCount += 1

                if self.writeErrorCount >= self.maxWriteErrors {
                    Task { @MainActor in
                        self.state = .failed(RecordingError.audioWriteFailure(error))
                    }
                }
            }

            self.levelMonitor?.processBuffer(buffer)
        }

        do {
            try engine.start()
        } catch {
            state = .failed(error)
            throw RecordingError.recordingFailed
        }

        self.audioEngine = engine
        self.audioFile = audioFile
        self.recordingURL = audioFilename
        self.state = .recording
        self.recordingDuration = 0
        self.writeErrorCount = 0

        startTimer()

        return audioFilename
    }

    func stopRecording() -> URL? {
        guard let engine = audioEngine, let url = recordingURL else {
            return nil
        }

        stopTimer()

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()

        self.audioEngine = nil
        self.audioFile = nil
        self.state = .idle

        return url
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopTimer()
        audioEngine?.stop()
    }
}

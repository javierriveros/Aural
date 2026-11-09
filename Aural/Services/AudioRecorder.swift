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
    func startRecording() throws -> URL
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

    func startRecording() throws -> URL {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            Task { _ = await requestPermission() }
        }
        guard status == .authorized else {
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
            settings: Self.fileSettings
        ) else {
            state = .failed(RecordingError.audioEngineFailure)
            throw RecordingError.audioEngineFailure
        }

        var downmixer: AVAudioConverter?
        if inputFormat.channelCount != 1 {
            guard let monoFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: inputFormat.sampleRate,
                channels: 1,
                interleaved: false
            ), let converter = AVAudioConverter(from: inputFormat, to: monoFormat) else {
                state = .failed(RecordingError.audioEngineFailure)
                throw RecordingError.audioEngineFailure
            }
            downmixer = converter
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }

            do {
                var output = buffer
                if let downmixer {
                    guard let mono = Self.monoBuffer(from: buffer, using: downmixer) else {
                        throw RecordingError.audioEngineFailure
                    }
                    output = mono
                }
                try audioFile.write(from: output)
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

    static let fileSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    static func monoBuffer(from buffer: AVAudioPCMBuffer, using converter: AVAudioConverter) -> AVAudioPCMBuffer? {
        guard let output = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: buffer.frameLength
        ) else { return nil }
        do {
            try converter.convert(to: output, from: buffer)
        } catch {
            return nil
        }
        return output
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

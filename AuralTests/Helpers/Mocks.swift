@testable import Aural
import Foundation

class AudioRecorderMock: AudioRecorderProtocol {
    var state: RecordingState = .idle
    var recordingDuration: TimeInterval = 0
    var monitor: AudioLevelMonitor?

    var requestPermissionReturnValue = true
    var startRecordingReturnValue: URL?
    var stopRecordingReturnValue: URL?

    var setLevelMonitorCalled = false
    var requestPermissionCalled = false
    var startRecordingCalled = false
    var stopRecordingCalled = false

    func setLevelMonitor(_ monitor: AudioLevelMonitor) {
        self.monitor = monitor
        setLevelMonitorCalled = true
    }

    func requestPermission() async -> Bool {
        requestPermissionCalled = true
        return requestPermissionReturnValue
    }

    func startRecording() async throws -> URL {
        startRecordingCalled = true
        if let url = startRecordingReturnValue {
            state = .recording
            return url
        }
        throw RecordingError.recordingFailed
    }

    func stopRecording() -> URL? {
        stopRecordingCalled = true
        state = .idle
        return stopRecordingReturnValue
    }
}

class AudioProcessorMock: AudioProcessorProtocol {
    var speedUpAudioCalled = false
    var estimateCostSavingsCalled = false

    var speedUpAudioHash: [URL: URL] = [:]

    func speedUpAudio(url: URL, speedMultiplier: Float) async throws -> URL {
        speedUpAudioCalled = true
        if let output = speedUpAudioHash[url] {
            return output
        }
        return url // Default pass-through
    }

    func estimateCostSavings(duration: TimeInterval, speedMultiplier: Float) -> Double {
        estimateCostSavingsCalled = true
        return 0.0
    }
}

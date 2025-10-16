import Foundation

@Observable
final class AppState {
    let audioRecorder = AudioRecorder()
    let hotkeyMonitor = HotkeyMonitor()

    private(set) var isRecording = false
    private var recordingURL: URL?

    init() {
        setupHotkeyCallbacks()
        _ = hotkeyMonitor.startMonitoring()
    }

    private func setupHotkeyCallbacks() {
        hotkeyMonitor.onKeyDown = { [weak self] in
            self?.startRecording()
        }

        hotkeyMonitor.onKeyUp = { [weak self] in
            self?.stopRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }

        Task { @MainActor in
            do {
                recordingURL = try await audioRecorder.startRecording()
                isRecording = true
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }

        Task { @MainActor in
            if let url = audioRecorder.stopRecording() {
                isRecording = false
                await handleRecordingComplete(url: url)
            }
        }
    }

    private func handleRecordingComplete(url: URL) async {
        print("Recording saved to: \(url.path)")
    }

    deinit {
        hotkeyMonitor.stopMonitoring()
    }
}

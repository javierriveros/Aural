import Foundation
import AppKit

@Observable
final class AppState {
    let audioRecorder = AudioRecorder()
    let hotkeyMonitor = HotkeyMonitor()
    let whisperService = WhisperService()

    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var lastTranscription: String?
    private(set) var lastError: String?
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
        isTranscribing = true
        lastError = nil

        do {
            let transcription = try await whisperService.transcribe(audioURL: url)
            lastTranscription = transcription
            copyToClipboard(transcription)

            try? FileManager.default.removeItem(at: url)
        } catch {
            lastError = error.localizedDescription
        }

        isTranscribing = false
    }

    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    deinit {
        hotkeyMonitor.stopMonitoring()
    }
}

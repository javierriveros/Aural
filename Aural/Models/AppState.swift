import Foundation
import AppKit
import SwiftData

@Observable
final class AppState {
    let audioRecorder = AudioRecorder()
    let hotkeyMonitor = HotkeyMonitor()
    let whisperService = WhisperService()

    var modelContext: ModelContext?

    private(set) var isRecording = false
    private(set) var isTranscribing = false
    private(set) var lastTranscription: String?
    private(set) var lastError: String?
    private var recordingURL: URL?
    private var recordingStartTime: Date?

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
                recordingStartTime = Date()
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

        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0

        do {
            let transcriptionText = try await whisperService.transcribe(audioURL: url)
            lastTranscription = transcriptionText
            copyToClipboard(transcriptionText)

            saveTranscription(text: transcriptionText, duration: duration)

            try? FileManager.default.removeItem(at: url)
        } catch {
            lastError = error.localizedDescription
        }

        isTranscribing = false
    }

    private func saveTranscription(text: String, duration: TimeInterval) {
        guard let context = modelContext else { return }

        let transcription = Transcription(text: text, duration: duration)
        context.insert(transcription)

        do {
            try context.save()
        } catch {
            print("Failed to save transcription: \(error)")
        }
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

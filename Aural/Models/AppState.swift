import Foundation
import AppKit
import SwiftData

@Observable
final class AppState {
    let audioRecorder = AudioRecorder()
    let hotkeyMonitor = HotkeyMonitor()
    let whisperService = WhisperService()
    let soundPlayer = SoundPlayer.shared

    var modelContext: ModelContext?

    private(set) var isRecording = false
    private(set) var isRecordingLocked = false
    private(set) var isTranscribing = false
    private(set) var lastTranscription: String?
    private(set) var lastError: String?
    private var recordingURL: URL?
    private var recordingStartTime: Date?

    var recordingMode: RecordingMode {
        RecordingModePreferences.mode
    }

    init() {
        setupHotkeyCallbacks()
        _ = hotkeyMonitor.startMonitoring()
    }

    private func setupHotkeyCallbacks() {
        hotkeyMonitor.onKeyDown = { [weak self] in
            self?.handleKeyDown()
        }

        hotkeyMonitor.onKeyUp = { [weak self] in
            self?.handleKeyUp()
        }

        hotkeyMonitor.onQuickTap = { [weak self] in
            self?.handleQuickTap()
        }
    }

    private func handleKeyDown() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .holdOnly, .hybrid:
            startRecording()
        case .tapToLock:
            break
        }
    }

    private func handleKeyUp() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .holdOnly:
            stopRecording()
        case .hybrid:
            if !isRecordingLocked {
                stopRecording()
            }
        case .tapToLock:
            break
        }
    }

    private func handleQuickTap() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .tapToLock, .hybrid:
            toggleLockedRecording()
        case .holdOnly:
            break
        }
    }

    private func toggleLockedRecording() {
        if isRecording && isRecordingLocked {
            stopRecording()
        } else if !isRecording {
            startLockedRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }

        soundPlayer.playRecordingStart()

        Task { @MainActor in
            do {
                recordingStartTime = Date()
                recordingURL = try await audioRecorder.startRecording()
                isRecording = true
                isRecordingLocked = false
            } catch {
                soundPlayer.playError()
                print("Failed to start recording: \(error)")
            }
        }
    }

    private func startLockedRecording() {
        guard !isRecording else { return }

        soundPlayer.playLockEngaged()

        Task { @MainActor in
            do {
                recordingStartTime = Date()
                recordingURL = try await audioRecorder.startRecording()
                isRecording = true
                isRecordingLocked = true
            } catch {
                soundPlayer.playError()
                print("Failed to start recording: \(error)")
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }

        soundPlayer.playRecordingStop()

        Task { @MainActor in
            if let url = audioRecorder.stopRecording() {
                isRecording = false
                isRecordingLocked = false
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

            soundPlayer.playTranscriptionComplete()
        } catch {
            lastError = error.localizedDescription
            soundPlayer.playError()
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

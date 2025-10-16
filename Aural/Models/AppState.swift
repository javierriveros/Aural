import Foundation
import AppKit
import SwiftData

@Observable
final class AppState {
    let audioRecorder = AudioRecorder()
    let hotkeyMonitor = HotkeyMonitor()
    let whisperService = WhisperService()
    let soundPlayer = SoundPlayer.shared
    let floatingWidget = FloatingWidgetController()
    let audioProcessor = AudioProcessor()
    let textInjectionService = TextInjectionService()

    var modelContext: ModelContext?

    private(set) var isRecording = false
    private(set) var isRecordingLocked = false
    private(set) var isTranscribing = false
    private(set) var lastTranscription: String?
    private(set) var lastError: String?
    private var recordingURL: URL?
    private var recordingStartTime: Date?
    private var widgetUpdateTimer: Timer?

    var recordingMode: RecordingMode {
        RecordingModePreferences.mode
    }

    var showFloatingWidget: Bool {
        get { UserDefaults.standard.bool(forKey: "show_floating_widget") }
        set {
            UserDefaults.standard.set(newValue, forKey: "show_floating_widget")
            updateFloatingWidgetVisibility()
        }
    }

    var audioSpeedMultiplier: Float {
        get {
            let value = UserDefaults.standard.float(forKey: "audio_speed_multiplier")
            return value > 0 ? value : 1.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "audio_speed_multiplier")
        }
    }

    var textInjectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "text_injection_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "text_injection_enabled") }
    }

    init() {
        UserDefaults.standard.register(defaults: [
            "show_floating_widget": true,
            "audio_speed_multiplier": 1.0,
            "text_injection_enabled": false
        ])
        setupHotkeyCallbacks()
        _ = hotkeyMonitor.startMonitoring()
        updateFloatingWidgetVisibility()
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
                startWidgetUpdateTimer()
            } catch {
                soundPlayer.playError()
                print("Failed to start recording: \(error)")
                updateFloatingWidget()
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
                startWidgetUpdateTimer()
            } catch {
                soundPlayer.playError()
                print("Failed to start recording: \(error)")
                updateFloatingWidget()
            }
        }
    }

    private func stopRecording() {
        guard isRecording else { return }

        soundPlayer.playRecordingStop()
        stopWidgetUpdateTimer()

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
        updateFloatingWidget()

        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0

        do {
            let processedURL: URL
            if audioSpeedMultiplier != 1.0 {
                processedURL = try await audioProcessor.speedUpAudio(
                    url: url,
                    speedMultiplier: audioSpeedMultiplier
                )
                try? FileManager.default.removeItem(at: url)
            } else {
                processedURL = url
            }

            let transcriptionText = try await whisperService.transcribe(audioURL: processedURL)
            lastTranscription = transcriptionText

            if textInjectionEnabled {
                do {
                    try textInjectionService.injectText(transcriptionText)
                } catch {
                    copyToClipboard(transcriptionText)
                }
            } else {
                copyToClipboard(transcriptionText)
            }

            saveTranscription(text: transcriptionText, duration: duration)

            try? FileManager.default.removeItem(at: processedURL)

            soundPlayer.playTranscriptionComplete()
        } catch {
            lastError = error.localizedDescription
            soundPlayer.playError()
            try? FileManager.default.removeItem(at: url)
        }

        isTranscribing = false
        updateFloatingWidget()
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

    private func updateFloatingWidgetVisibility() {
        if showFloatingWidget {
            floatingWidget.show()
            updateFloatingWidget()
        } else {
            floatingWidget.hide()
        }
    }

    private func updateFloatingWidget() {
        let state: WidgetState
        if isTranscribing {
            state = .transcribing
        } else if isRecording {
            let duration = audioRecorder.recordingDuration
            state = .recording(duration: duration, isLocked: isRecordingLocked)
        } else {
            state = .idle
        }
        floatingWidget.updateState(state)
    }

    private func startWidgetUpdateTimer() {
        stopWidgetUpdateTimer()
        widgetUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateFloatingWidget()
        }
    }

    private func stopWidgetUpdateTimer() {
        widgetUpdateTimer?.invalidate()
        widgetUpdateTimer = nil
    }

    deinit {
        hotkeyMonitor.stopMonitoring()
        stopWidgetUpdateTimer()
    }
}

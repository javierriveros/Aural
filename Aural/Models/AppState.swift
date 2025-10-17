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
    let vocabularyService = VocabularyService()
    let voiceCommandProcessor = VoiceCommandProcessor()
    let shortcutManager = ShortcutManager()

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
        get { UserDefaults.standard.bool(forKey: UserDefaultsKeys.showFloatingWidget) }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.showFloatingWidget)
            updateFloatingWidgetVisibility()
        }
    }

    var audioSpeedMultiplier: Float {
        get {
            let value = UserDefaults.standard.float(forKey: UserDefaultsKeys.audioSpeedMultiplier)
            return value > 0 ? value : 1.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.audioSpeedMultiplier)
        }
    }

    var textInjectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: UserDefaultsKeys.textInjectionEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.textInjectionEnabled) }
    }

    init() {
        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.showFloatingWidget: true,
            UserDefaultsKeys.audioSpeedMultiplier: 1.0,
            UserDefaultsKeys.textInjectionEnabled: false
        ])
        setupHotkeyCallbacks()
        setupFloatingWidgetCallbacks()
        setupShortcutCallbacks()
        if !hotkeyMonitor.startMonitoring() {
            print("Warning: Failed to start hotkey monitoring")
        }
        updateFloatingWidgetVisibility()
    }

    private func setupFloatingWidgetCallbacks() {
        floatingWidget.onTap = { [weak self] in
            self?.handleWidgetTap()
        }
    }

    private func handleWidgetTap() {
        if isRecording {
            if isRecordingLocked {
                stopRecording()
            }
        } else if !isTranscribing {
            startLockedRecording()
        }
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

    private func setupShortcutCallbacks() {
        shortcutManager.onShortcutTriggered = { [weak self] action in
            self?.handleShortcut(action)
        }
    }

    private func handleShortcut(_ action: ShortcutAction) {
        Task { @MainActor in
            switch action {
            case .copyLastTranscription:
                if let transcription = lastTranscription {
                    ClipboardService.copy(transcription)
                }
            case .showHideWindow:
                NSApp.activate(ignoringOtherApps: true)
            case .openSettings:
                break
            case .clearHistory:
                guard let context = modelContext else { return }
                do {
                    try context.delete(model: Transcription.self)
                    try context.save()
                } catch {
                    print("Failed to clear history: \(error)")
                }
            }
        }
    }

    private func handleKeyDown() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .holdOnly, .hybrid:
            if !isRecording {
                startRecording()
            }
        case .tapToLock:
            break
        }
    }

    private func handleKeyUp() {
        let mode = RecordingModePreferences.mode

        switch mode {
        case .holdOnly, .hybrid:
            if isRecording {
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
        } else if isRecording && !isRecordingLocked {
            isRecordingLocked = true
            updateFloatingWidget()
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

            let rawTranscription = try await whisperService.transcribe(audioURL: processedURL)
            let withVocabulary = vocabularyService.applyWordBoundaryReplacements(to: rawTranscription)
            let transcriptionText = voiceCommandProcessor.process(withVocabulary)
            lastTranscription = transcriptionText

            if textInjectionEnabled {
                do {
                    try textInjectionService.injectText(transcriptionText)
                } catch {
                    ClipboardService.copy(transcriptionText)
                }
            } else {
                ClipboardService.copy(transcriptionText)
            }

            saveTranscription(text: transcriptionText, duration: duration)

            FileManager.default.safelyRemoveItem(at: processedURL)

            soundPlayer.playTranscriptionComplete()
        } catch {
            lastError = error.localizedDescription
            soundPlayer.playError()
            FileManager.default.safelyRemoveItem(at: url)
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

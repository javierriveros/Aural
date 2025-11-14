import AppKit
import Foundation
import SwiftData

@Observable
final class AppState {
    let audioRecorder = AudioRecorder()
    let hotkeyMonitor = HotkeyMonitor()
    let whisperService = WhisperService()
    let soundPlayer = SoundPlayer.shared
    let floatingWidget = FloatingWidgetController()
    let waveformWindow = WaveformWindowController()
    let audioLevelMonitor = AudioLevelMonitor()
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

    var widgetDisplayMode: WidgetDisplayMode {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: UserDefaultsKeys.widgetDisplayMode),
               let mode = WidgetDisplayMode(rawValue: rawValue) {
                return mode
            }
            return .waveform  // Default to waveform mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.widgetDisplayMode)
            updateFloatingWidgetVisibility()
        }
    }

    // Legacy support - maps to widgetDisplayMode
    var showFloatingWidget: Bool {
        get { widgetDisplayMode != .none }
        set {
            // When set to false, use .none, otherwise use current mode or default
            widgetDisplayMode = newValue ? (widgetDisplayMode == .none ? .waveform : widgetDisplayMode) : .none
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
        setupWaveformWindowCallbacks()
        setupShortcutCallbacks()
        setupAudioLevelMonitor()
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

    private func setupWaveformWindowCallbacks() {
        waveformWindow.onTap = { [weak self] in
            self?.handleWidgetTap()
        }
    }

    private func setupAudioLevelMonitor() {
        audioRecorder.setLevelMonitor(audioLevelMonitor)
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
            updateRecordingVisualization()  // Update visualization with new locked state
        } else if !isRecording {
            startLockedRecording()
        }
    }

    private func startRecording() {
        guard !isRecording else { return }

        soundPlayer.playRecordingStart()
        audioLevelMonitor.reset()

        Task { @MainActor in
            do {
                recordingStartTime = Date()
                recordingURL = try await audioRecorder.startRecording()
                isRecording = true
                isRecordingLocked = false
                updateFloatingWidgetVisibility()  // Ensure proper widget visibility
                startWidgetUpdateTimer()
                updateRecordingVisualization()
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
        audioLevelMonitor.reset()

        Task { @MainActor in
            do {
                recordingStartTime = Date()
                recordingURL = try await audioRecorder.startRecording()
                isRecording = true
                isRecordingLocked = true
                updateFloatingWidgetVisibility()  // Ensure proper widget visibility
                startWidgetUpdateTimer()
                updateRecordingVisualization()
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
                updateFloatingWidgetVisibility()  // Show simple widget again when idle
                await handleRecordingComplete(url: url)
            }
        }
    }

    private func handleRecordingComplete(url: URL) async {
        let duration = recordingStartTime.map { Date().timeIntervalSince($0) } ?? 0

        if duration <= 1.0 {
            FileManager.default.safelyRemoveItem(at: url)
            updateFloatingWidget()
            return
        }

        isTranscribing = true
        lastError = nil
        updateFloatingWidget()

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

            // Calculate cost: $0.006 per minute
            let costPerMinute = 0.006
            let durationInMinutes = duration / 60.0
            let cost = durationInMinutes * costPerMinute

            saveTranscription(text: transcriptionText, duration: duration, cost: cost)

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

    private func saveTranscription(text: String, duration: TimeInterval, cost: Double) {
        guard let context = modelContext else { return }

        let transcription = Transcription(text: text, duration: duration, cost: cost)
        context.insert(transcription)

        do {
            try context.save()
        } catch {
            print("Failed to save transcription: \(error)")
        }
    }

    private func updateFloatingWidgetVisibility() {
        switch widgetDisplayMode {
        case .none:
            // Hide both widgets
            floatingWidget.hide()
            waveformWindow.hide()
        case .simple:
            // Show simple widget, hide waveform window
            floatingWidget.show()
            updateFloatingWidget()
            waveformWindow.hide()
        case .waveform:
            // In waveform mode: only show waveform window when recording, nothing when idle
            if isRecording {
                floatingWidget.hide()
                // Waveform window is shown/updated by updateRecordingVisualization()
            } else {
                // Hide both widgets when idle in waveform mode
                floatingWidget.hide()
                waveformWindow.hide()
            }
        }
    }

    private func updateFloatingWidget() {
        // Don't update simple widget when in waveform mode
        // (in waveform mode, only the waveform window is shown during recording, nothing when idle)
        if widgetDisplayMode == .waveform {
            return
        }

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

    private func updateRecordingVisualization() {
        switch widgetDisplayMode {
        case .none:
            // No visualization
            break
        case .simple:
            // Update simple widget
            updateFloatingWidget()
        case .waveform:
            // Show waveform window, hide simple widget
            floatingWidget.hide()
            let duration = audioRecorder.recordingDuration
            waveformWindow.show(
                duration: duration,
                isLocked: isRecordingLocked,
                levelMonitor: audioLevelMonitor
            )
        }
    }

    private func startWidgetUpdateTimer() {
        stopWidgetUpdateTimer()

        // Use different update rates for waveform vs simple widget
        // Waveform needs 60 FPS for smooth animation, simple widget only needs 10 FPS
        let updateInterval: TimeInterval = (widgetDisplayMode == .waveform && isRecording) ? 1.0/60.0 : 0.1

        // Create timer and add to run loop with common mode for better performance
        let timer = Timer(timeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.widgetDisplayMode == .waveform && self.isRecording {
                // Update waveform window with latest audio levels at 60 FPS
                self.updateRecordingVisualization()
            } else {
                // Update simple widget at 10 FPS (sufficient for duration counter)
                self.updateFloatingWidget()
            }
        }

        RunLoop.current.add(timer, forMode: .common)
        widgetUpdateTimer = timer
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

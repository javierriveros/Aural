import Foundation
import CoreGraphics
import AVFoundation

// MARK: - User Defaults Keys

enum UserDefaultsKeys {
    static let openAIAPIKey = "openai_api_key"
    static let showFloatingWidget = "show_floating_widget"
    static let audioSpeedMultiplier = "audio_speed_multiplier"
    static let textInjectionEnabled = "text_injection_enabled"
    static let soundsEnabled = "sounds_enabled"
    static let recordingMode = "recording_mode"
    static let quickTapThreshold = "quick_tap_threshold"
    static let customHotkey = "custom_hotkey"
    static let customVocabulary = "custom_vocabulary"
    static let voiceCommandsEnabled = "voice_commands_enabled"
}

// MARK: - Audio Settings

enum AudioSettings {
    static let formatID = Int(kAudioFormatMPEG4AAC)
    static let sampleRate = 44100.0
    static let numberOfChannels = 1
    static let quality = AVAudioQuality.high
}

// MARK: - Keyboard Constants

enum KeyboardConstants {
    static let fnKeyCode: CGKeyCode = 0x3F
    static let quickTapThresholdSeconds: TimeInterval = 0.3
    static let keystrokeDelayMicroseconds: useconds_t = 1_000
}

// MARK: - Timer Constants

enum TimerConstants {
    static let widgetUpdateInterval: TimeInterval = 0.1
    static let durationUpdateInterval: TimeInterval = 0.1
}

// MARK: - API Constants

enum APIConstants {
    static let whisperAPIURL = "https://api.openai.com/v1/audio/transcriptions"
    static let whisperModel = "whisper-1"
    static let whisperPricePerMinute = 0.006
}

// MARK: - UI Constants

enum UIConstants {
    static let floatingWidgetWidth: CGFloat = 280
    static let floatingWidgetHeight: CGFloat = 80
    static let floatingWidgetCornerRadius: CGFloat = 12
    static let floatingWidgetPadding: CGFloat = 20
}

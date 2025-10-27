# Changelog

All notable changes to Aural will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SwiftLint configuration and linting guide for code quality
- `.swiftlint.yml` with sensible defaults

## [1.0.0] - 2025-10-16

### Added

- **Core Features**

  - Global hotkey recording with customizable hotkeys (default: Fn key)
  - AI-powered transcription using OpenAI Whisper API
  - Automatic clipboard copy of transcriptions
  - SwiftData-based transcription history
  - Modern SwiftUI interface with animations

- **Recording Modes**

  - Hold Only mode (classic push-to-talk)
  - Tap to Lock mode (toggle recording)
  - Hybrid mode (hold for temporary, tap for locked)

- **Smart Features**

  - Custom Vocabulary with word/phrase replacements
  - Voice Commands for punctuation, formatting, and editing
  - Keyboard Shortcuts for common actions
  - Audio Speed Processing (1.5x-2.0x) to reduce API costs
  - Text Injection at cursor position (via Accessibility)

- **UI/UX**

  - Floating widget with recording status
  - Animated recording indicators with pulse effects
  - Sound effects for user feedback
  - Modern design system with brand colors
  - Dark mode support

- **Security & Reliability**

  - API key storage in UserDefaults
  - Safe optional handling (zero force unwraps)
  - Proper error handling with typed errors
  - Memory leak prevention
  - Resource cleanup for temporary files

- **Services**
  - AudioRecorder with error tracking
  - AudioProcessor for speed manipulation
  - WhisperService for OpenAI API integration
  - HotkeyMonitor for global event monitoring
  - TextInjectionService for accessibility-based typing
  - VocabularyService for custom replacements
  - VoiceCommandProcessor for natural language commands
  - ShortcutManager for keyboard shortcuts
  - SoundPlayer for audio feedback

### Changed

- Improved API key validation with real audio file testing
- Enhanced permission request flow with auto-detection
- Modernized UI with gradient colors and smooth animations

### Fixed

- Force unwraps replaced with safe optional binding
- Timer retain cycles prevented with weak references
- Silent audio write failures now properly reported
- Temporary file cleanup on processing failures
- Permission popup no longer appears repeatedly
- Documentation corrections for API key storage

[Unreleased]: https://github.com/javierriveros/aural/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/javierriveros/aural/releases/tag/v1.0.0

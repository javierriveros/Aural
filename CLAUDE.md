# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Aural is a macOS (14.0+) voice dictation app built in SwiftUI + SwiftData. A global hotkey records audio, which is transcribed by either a cloud API (OpenAI, Groq) or a local on-device model (Whisper via SwiftWhisper, Parakeet via FluidAudio), then post-processed and injected at the cursor or copied to the clipboard.

## Build, Test, Lint

Xcode project (no SPM manifest at root). Scheme is `Aural`; targets are `Aural` and `AuralTests`. Two package dependencies are resolved via Xcode: `SwiftWhisper` (Whisper) and `FluidAudio` (Parakeet).

```bash
# Build
xcodebuild build -scheme Aural -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Run all tests (matches CI)
xcodebuild test -project Aural.xcodeproj -scheme Aural \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

# Run a single test class or method
xcodebuild test -project Aural.xcodeproj -scheme Aural \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:AuralTests/VocabularyServiceTests \
  -only-testing:AuralTests/VocabularyServiceTests/testWordBoundaryReplacement

# Lint (CI fails on violations)
swiftlint lint
```

CI (`.github/workflows/ci.yml`) runs three jobs on macOS: SwiftLint, build+test (arm64, parallel testing disabled), and a Release build. `force_cast` and `force_try` are SwiftLint **errors** — avoid `as!` and `try!`. Mixed test frameworks are present: some tests use XCTest, others Swift Testing.

## Architecture

### AppState is the hub (`Aural/Models/AppState.swift`)
A single `@Observable final class AppState` owns all services and orchestrates the entire flow. It is the dependency-injection root — services are constructed and held here, not resolved globally. When wiring new behavior, the wiring usually lives in `AppState`'s `setup*Callbacks()` methods and the recording state machine. Settings are persisted to `UserDefaults` (keys in `UserDefaultsKeys`) and read back in `init`.

### Recording state machine
`HotkeyMonitor` fires global key events → `AppState.handleKeyDown/handleKeyUp/handleQuickTap` interpret them according to the active `RecordingMode` (`.holdOnly`, `.tapToLock`, `.hybrid`). Recordings shorter than 1.0s are discarded. Recording start/stop drives the floating widget and waveform/orb visualizations.

### Transcription pipeline (`handleRecordingComplete`)
The post-recording flow is a fixed, ordered pipeline — preserve this order when modifying:
1. Optional audio speed-up (`AudioProcessor`) to cut API cost
2. `provider.transcribe(audioURL:)` — provider chosen by `getTranscriptionProvider()`
3. `TextCleanupService.cleanup` — filler-word / stutter removal
4. `VocabularyService.applyWordBoundaryReplacements` — custom word replacement
5. `VoiceCommandProcessor.process` — punctuation/formatting/editing commands
6. Text injection (`TextInjectionService`, Accessibility-based) with clipboard fallback, then persist a `Transcription` via SwiftData

### Provider abstraction (`Aural/Services/TranscriptionProvider.swift`)
All transcription backends conform to `TranscriptionProvider` (`transcribe(audioURL:) async throws -> String`, `isAvailable`, optional `preload()`). `AppState.getTranscriptionProvider()` selects one based on `TranscriptionMode` (`.cloud`/`.local`) + the chosen `CloudProvider` or `ModelFamily`. To add a backend, implement the protocol and add a branch in `getTranscriptionProvider()` / `getProviderName()` / `calculateCost()`. `preload()` exists so local models can be loaded into memory ahead of first use.

### Local models
`ModelRegistry` defines available `TranscriptionModel`s; `ModelDownloadManager` handles download/status; `LocalWhisperService` and `LocalParakeetService` wrap the respective SDKs. Local services are optional (`?`) on `AppState` because the SDKs must be added in Xcode and models downloaded before use.

### UI layers
- **Views/** — SwiftUI, UI-only. Multiple recording visualizers exist (`OrbRecordingView`, `WaveformRecordingView`, `RecordingIndicatorView`) selected by `WidgetDisplayMode`.
- **Controllers/** — `FloatingWidgetController` and `WaveformWindowController` manage borderless `NSPanel` windows (the always-on-top floating widget).
- **Utilities/DesignSystem.swift** — design tokens (colors, spacing, fonts). Use these rather than hardcoded values.

## Conventions (from CONTRIBUTING.md)

- Use `@Observable` for state, not `@StateObject`/`@ObservedObject`.
- No force unwraps; prefer `guard let`/`if let` and `guard` for early returns.
- Services are stateless where possible and suffixed `Service`; bool properties prefixed `is`/`has`/`should`.
- Typed errors as `LocalizedError` enums with `errorDescription` (see `TranscriptionErrors.swift`, `RecordingError`).
- Use `[weak self]` in escaping closures and implement `deinit` to clean up timers / event monitors / temp files.
- Conventional commits: `<type>(<scope>): <subject>` (feat, fix, refactor, perf, docs, style, test, chore).

## Notes

- API keys are stored in `UserDefaults` (not Keychain) — by design, documented in README.
- Temporary audio files are removed after transcription via `FileManager.safelyRemoveItem`; preserve cleanup paths in error branches.
- `Data/` holds local model weights and is not source. `TestResult.xcresult`/`build.log` are local artifacts.

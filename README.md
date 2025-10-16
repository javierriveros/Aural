# Aural

A macOS voice dictation app that lets you quickly transcribe speech to text using OpenAI's Whisper API.

## Features

- **Global Hotkey Recording**: Hold the Fn key from anywhere to start recording
- **Automatic Transcription**: Audio is sent to OpenAI Whisper API for high-quality transcription
- **Instant Clipboard**: Transcriptions are automatically copied to your clipboard
- **History Management**: View, search, and manage all your past transcriptions
- **Native macOS**: Built with SwiftUI for a native look and feel

## Requirements

- macOS 14.0 (Sonoma) or later
- OpenAI API key with access to Whisper API
- Microphone access
- Accessibility permissions (for global hotkey monitoring)

## Setup

### 1. Get an OpenAI API Key

1. Visit [platform.openai.com](https://platform.openai.com)
2. Create an account or sign in
3. Navigate to API keys section
4. Create a new API key
5. Copy the key (you'll need it in step 3)

### 2. Build and Run

1. Open `Aural.xcodeproj` in Xcode
2. Build and run the project (⌘R)

### 3. Configure API Key

1. Click the gear icon in the toolbar
2. Paste your OpenAI API key
3. Optionally, test the API key to verify it works
4. Click "Save"

### 4. Grant Permissions

When you first use the app, you'll be prompted to grant:
- **Microphone access**: Required to record audio
- **Accessibility permissions**: Required for global hotkey monitoring

To manually grant accessibility permissions:
1. Open System Settings
2. Go to Privacy & Security → Accessibility
3. Enable Aural

## Usage

### Recording and Transcription

1. **Hold the Fn key** anywhere on your Mac to start recording
2. **Speak** your message clearly
3. **Release the Fn key** to stop recording
4. Wait a moment while the audio is transcribed
5. The transcription is **automatically copied to your clipboard**
6. Paste it anywhere with ⌘V

### Managing History

- View all your transcriptions in the main window
- Click "Copy" to copy a transcription again
- Click "Delete" to remove a transcription
- Transcriptions are sorted by most recent first

## Architecture

### Core Components

- **AudioRecorder**: Manages microphone input and audio file creation using AVFoundation
- **HotkeyMonitor**: Monitors global Fn key events using Carbon/CGEvent APIs
- **WhisperService**: Handles API communication with OpenAI Whisper
- **AppState**: Coordinates all components and manages application state
- **SwiftData**: Persists transcription history locally

### Tech Stack

- SwiftUI (UI framework)
- SwiftData (data persistence)
- AVFoundation (audio recording)
- Carbon API (global hotkey monitoring)
- URLSession (API networking)

## Privacy

- All audio files are temporarily stored locally and deleted after transcription
- Transcription history is stored locally using SwiftData
- API key is stored in UserDefaults (not secure; consider Keychain for production)
- Audio is sent to OpenAI servers for transcription

## Troubleshooting

### Hotkey not working
- Verify accessibility permissions are granted
- Check that no other app is using the Fn key globally

### Recording not starting
- Check microphone permissions in System Settings
- Ensure no other app is using the microphone

### Transcription failing
- Verify your OpenAI API key is valid
- Check your internet connection
- Ensure you have API credits/billing enabled

### Build errors
- Ensure you're using Xcode 15+ with macOS SDK 14+
- Clean build folder (⌘⇧K) and rebuild

## Development

### Project Structure
```
Aural/
├── Models/
│   ├── AppState.swift          # Global app state coordinator
│   ├── Transcription.swift     # SwiftData model
│   └── WhisperResponse.swift   # API response model
├── Services/
│   ├── AudioRecorder.swift     # Audio recording logic
│   ├── HotkeyMonitor.swift     # Global hotkey detection
│   └── WhisperService.swift    # Whisper API integration
├── Views/
│   ├── ContentView.swift       # Main window
│   ├── SettingsView.swift      # Settings panel
│   ├── RecordingIndicatorView.swift  # Recording status
│   └── TranscriptionRow.swift  # History item
└── AuralApp.swift             # App entry point
```

### Future Enhancements

- [ ] Menu bar mode (run in background)
- [ ] Direct text injection at cursor position
- [ ] Custom hotkey configuration
- [ ] Local Whisper model support (privacy-focused)
- [ ] Multiple language support
- [ ] Secure API key storage (Keychain)
- [ ] Export history to CSV/JSON
- [ ] Audio playback of recordings
- [ ] Edit transcriptions in-app

## License

MIT License - see LICENSE file for details

## Credits

Built with [Claude Code](https://claude.com/claude-code)

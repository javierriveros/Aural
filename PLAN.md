# Aural - Voice Dictation App Implementation Plan

## Project Overview
Build a macOS voice dictation app similar to Whispr Flow/SuperWhisper that allows users to hold a key to record audio, transcribe it using OpenAI Whisper API, and paste the text at the cursor position.

## Core Features (MVP)
- Hold designated key → start recording
- Release key → stop recording, transcribe via Whisper API
- Auto-copy transcription to clipboard
- Display transcription history in app
- Basic settings for API key configuration

## Architecture Components

### 1. Audio Recording Layer
- **Technology**: AVFoundation (AVAudioRecorder/AVAudioEngine)
- **Responsibilities**:
  - Request microphone permissions
  - Start/stop recording on hotkey events
  - Save audio files in Whisper-compatible format (M4A, MP3, or WAV)
  - Clean up temporary audio files after transcription

### 2. Global Hotkey System
- **Technology**: Carbon API / Cocoa NSEvent
- **Responsibilities**:
  - Monitor global key press/release events (app doesn't need focus)
  - Request accessibility permissions
  - Trigger recording start/stop
  - Handle edge cases (rapid presses, held keys)

### 3. Transcription Service
- **Technology**: OpenAI Whisper API (REST)
- **Responsibilities**:
  - Upload audio file to Whisper API
  - Handle API authentication (API key)
  - Parse transcription response
  - Error handling (network, API errors, rate limits)

### 4. Text Output System
- **Phase 1 (MVP)**: Copy to clipboard using NSPasteboard
- **Phase 2**: Direct text injection at cursor using Accessibility API (CGEvent)
- **Responsibilities**:
  - Place transcribed text on clipboard
  - (Future) Simulate typing at cursor position

### 5. Data Persistence
- **Technology**: SwiftData (iOS 17+/macOS 14+) or Core Data
- **Responsibilities**:
  - Store transcription history (text, timestamp, audio duration)
  - Query and display history
  - Export/delete history entries

### 6. User Interface
- **Technology**: SwiftUI
- **Components**:
  - Main window: transcription history list
  - Recording indicator: visual feedback during recording
  - Settings panel: API key, hotkey configuration
  - Menu bar (Phase 2): quick access, status indicator

---

## Implementation Phases

### Phase 0: Project Setup ✓
**Goal**: Prepare project structure and configuration

- [x] Create basic macOS SwiftUI app
- [ ] Set up folder structure (Models/, Services/, Views/)
- [ ] Add required Info.plist permissions
  - `NSMicrophoneUsageDescription`
  - `NSAppleEventsUsageDescription` (for accessibility)
- [ ] Create PLAN.md (this file)

**Files to create**:
- Info.plist entries
- Folder structure

---

### Phase 1: Audio Recording
**Goal**: Record audio from microphone and save to disk

**Tasks**:
1. Create `Services/AudioRecorder.swift`
   - Set up AVAudioSession for macOS
   - Implement `startRecording()` method
   - Implement `stopRecording()` method returning file URL
   - Request microphone permissions
   - Save recordings to temporary directory

2. Create `Views/RecordingIndicatorView.swift`
   - Simple visual indicator (red circle when recording)
   - Display recording duration timer

3. Test in ContentView
   - Add manual start/stop buttons for testing
   - Display recording status and file path

**Success Criteria**:
- Can record audio and save to M4A/WAV file
- Microphone permission properly requested
- Visual feedback during recording

**Files to create**:
- `Services/AudioRecorder.swift`
- `Views/RecordingIndicatorView.swift`

**Files to modify**:
- `ContentView.swift` (add test UI)
- Info.plist (add microphone permission)

---

### Phase 2: Global Hotkey Monitoring
**Goal**: Detect key press/release globally, even when app not focused

**Tasks**:
1. Create `Services/HotkeyMonitor.swift`
   - Use `NSEvent.addGlobalMonitorForEvents(matching:handler:)`
   - Monitor `.flagsChanged` or `.keyDown`/`.keyUp` for specific key (e.g., Fn, Right Command)
   - Implement callbacks for key down/up events
   - Request accessibility permissions if needed

2. Integrate with AudioRecorder
   - Key down → start recording
   - Key up → stop recording

3. Handle edge cases
   - Prevent multiple simultaneous recordings
   - Handle key held for extended periods
   - Graceful handling if permissions denied

**Success Criteria**:
- Can start/stop recording by holding/releasing designated key
- Works when other apps are focused
- Accessibility permission properly requested

**Files to create**:
- `Services/HotkeyMonitor.swift`

**Files to modify**:
- `AuralApp.swift` (initialize hotkey monitor)
- Info.plist (add accessibility permission if needed)

---

### Phase 3: Whisper API Integration
**Goal**: Send audio files to OpenAI Whisper API and get transcription

**Tasks**:
1. Create `Services/WhisperService.swift`
   - Implement `transcribe(audioURL:) async throws -> String`
   - Build multipart/form-data request for audio file
   - Add API key authentication (Bearer token)
   - Parse JSON response
   - Error handling (network, 401, 429, etc.)

2. Create `Models/WhisperResponse.swift`
   - Codable model for API response

3. Store API key securely
   - Use UserDefaults for MVP (not secure)
   - TODO for Phase 4: Use Keychain

4. Test with sample audio file
   - Create test harness in ContentView
   - Display transcription result

**Success Criteria**:
- Can successfully transcribe a test audio file
- Proper error messages for common failures
- API key stored and loaded correctly

**Files to create**:
- `Services/WhisperService.swift`
- `Models/WhisperResponse.swift`

**Files to modify**:
- `ContentView.swift` (add test UI)

**API Reference**:
```
POST https://api.openai.com/v1/audio/transcriptions
Content-Type: multipart/form-data
Authorization: Bearer YOUR_API_KEY

Fields:
- file: (audio file)
- model: "whisper-1"
- response_format: "text" or "json"
```

---

### Phase 4: Data Models & Persistence
**Goal**: Store and retrieve transcription history

**Tasks**:
1. Create `Models/Transcription.swift`
   - Properties: id, text, timestamp, duration, audioFileURL
   - SwiftData @Model or Core Data Entity

2. Create `Services/DataService.swift` (if using Core Data)
   - Or use SwiftData container directly in App

3. Set up SwiftData container in `AuralApp.swift`
   - Add `.modelContainer(for: Transcription.self)`

4. Implement CRUD operations
   - Save new transcription
   - Fetch all transcriptions (sorted by date)
   - Delete transcription

**Success Criteria**:
- Transcriptions persist across app launches
- Can view history of past transcriptions
- Can delete old entries

**Files to create**:
- `Models/Transcription.swift`

**Files to modify**:
- `AuralApp.swift` (set up data container)

---

### Phase 5: Text Output (Clipboard)
**Goal**: Automatically copy transcription to clipboard

**Tasks**:
1. Create `Services/ClipboardService.swift`
   - Use `NSPasteboard.general`
   - Implement `copy(text:)` method
   - Optional: show notification on copy

2. Integrate with transcription flow
   - After successful transcription → copy to clipboard
   - Save to history database

3. Add user notification
   - Show macOS notification with preview of transcribed text
   - Request notification permissions

**Success Criteria**:
- Transcription automatically copied to clipboard
- User can paste into any app immediately
- Notification shows success feedback

**Files to create**:
- `Services/ClipboardService.swift`

**Files to modify**:
- Info.plist (notification permission if needed)

---

### Phase 6: Main UI - History View
**Goal**: Display list of past transcriptions in main window

**Tasks**:
1. Update `ContentView.swift`
   - Use `@Query` (SwiftData) or `@FetchRequest` (Core Data)
   - List view showing transcriptions
   - Each row: timestamp, text preview
   - Tap to copy, swipe to delete

2. Create `Views/TranscriptionRow.swift`
   - Reusable row component
   - Show timestamp, text, duration
   - Copy button, delete button

3. Add empty state
   - Show helpful message when no transcriptions yet

4. Add search/filter (optional for MVP)

**Success Criteria**:
- History displays all transcriptions chronologically
- Can interact with each entry (copy, delete)
- Clean, readable UI

**Files to create**:
- `Views/TranscriptionRow.swift`

**Files to modify**:
- `ContentView.swift` (replace placeholder with history)

---

### Phase 7: Settings View
**Goal**: Allow user to configure API key and preferences

**Tasks**:
1. Create `Views/SettingsView.swift`
   - API key input (SecureField)
   - Test API key button
   - Hotkey configuration display (read-only for MVP)
   - About section (version, links)

2. Add Settings button to main window
   - Toolbar button or menu item
   - Opens settings in sheet or separate window

3. Implement API key storage
   - Save to UserDefaults for MVP
   - Load on app launch
   - TODO: Migrate to Keychain in future

4. Add validation
   - Check API key format
   - Test connection to Whisper API

**Success Criteria**:
- User can enter and save API key
- API key persists across launches
- Can test API key validity

**Files to create**:
- `Views/SettingsView.swift`

**Files to modify**:
- `ContentView.swift` (add settings button)
- `AuralApp.swift` (if settings as separate window)

---

### Phase 8: Integration & Polish
**Goal**: Connect all components and refine UX

**Tasks**:
1. Wire complete flow
   - Hotkey → Recording → Transcription → Clipboard → History
   - Handle loading states (show "Transcribing..." indicator)
   - Handle error states (show alerts)

2. Add app state management
   - Create `AppState.swift` ObservableObject
   - Track: isRecording, isTranscribing, currentRecordingDuration

3. Error handling & user feedback
   - Permission errors: show guidance to enable in System Settings
   - API errors: show user-friendly messages
   - Network errors: retry mechanism

4. Visual polish
   - Recording pulse animation
   - Smooth transitions
   - Status bar indicator

5. Testing
   - Test full flow end-to-end
   - Test error scenarios
   - Test with various audio lengths

**Success Criteria**:
- Complete flow works smoothly
- Clear feedback at every stage
- Graceful error handling

**Files to create**:
- `Models/AppState.swift`

**Files to modify**:
- All views and services (integration)

---

## Phase 2.0: Future Enhancements (Post-MVP)

### Menu Bar Mode
- Hide dock icon
- Show status in menu bar
- Quick access to history and settings
- "Start Recording" manual trigger

### Advanced Features
- Direct text injection at cursor (instead of clipboard)
- Custom hotkey configuration
- Multiple language support
- Local Whisper model (on-device, private)
- Audio playback of recordings
- Export history to CSV/JSON
- Keyboard shortcuts for app actions

### Quality of Life
- Secure API key storage (Keychain)
- Recording audio format options
- Trim silence from recordings
- Transcription editing
- Cloud sync of history

---

## Development Guidelines

### Code Quality Standards
- **Best Practices**: Follow Swift and SwiftUI best practices for macOS
- **No Workarounds**: Avoid hackish solutions; implement properly from the start
- **Well Structured**: Maintain clean architecture with clear separation of concerns
- **Minimal Comments**: Code should be self-documenting; avoid redundant comments
- **Git Workflow**: Commit at the end of each phase with descriptive messages

### Swift/SwiftUI Principles
- Use modern Swift concurrency (async/await, actors where appropriate)
- Leverage SwiftUI lifecycle and state management (@Observable, @State, etc.)
- Follow Apple's Human Interface Guidelines for macOS
- Use native frameworks over third-party when possible
- Proper error handling with typed throws (Swift 6+)

---

## Technical Decisions

### Why SwiftUI?
- Modern, declarative UI
- Great integration with SwiftData
- Native macOS look and feel

### Why OpenAI Whisper API?
- High accuracy
- Simple REST API
- No need for local model management (MVP)
- Can switch to local model later

### Why Clipboard over Direct Injection?
- Much simpler implementation for MVP
- Works reliably across all apps
- No complex accessibility API handling
- Can add injection in v2

### Audio Format Choice
- M4A (AAC): Good compression, widely supported
- Alternative: WAV for quality, MP3 for compatibility
- Whisper API accepts: flac, m4a, mp3, mp4, mpeg, mpga, oga, ogg, wav, webm

---

## Required Permissions (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Aural needs access to your microphone to record audio for transcription.</string>

<key>NSAppleEventsUsageDescription</key>
<string>Aural needs accessibility access to monitor the hotkey for voice recording.</string>
```

---

## Dependencies

### Native Frameworks
- AVFoundation (audio recording)
- Foundation (networking, file I/O)
- SwiftUI (UI)
- SwiftData (persistence)
- AppKit (clipboard, notifications, global events)

### External (if needed later)
- None for MVP
- Possible: KeychainAccess (secure storage), Sparkle (auto-updates)

---

## File Structure

```
Aural/
├── AuralApp.swift                 # App entry point
├── Info.plist                     # Permissions and config
├── PLAN.md                        # This file
│
├── Models/
│   ├── Transcription.swift        # Data model for history
│   ├── WhisperResponse.swift      # API response model
│   └── AppState.swift             # App-wide state
│
├── Services/
│   ├── AudioRecorder.swift        # Audio recording manager
│   ├── HotkeyMonitor.swift        # Global hotkey detection
│   ├── WhisperService.swift       # Whisper API integration
│   └── ClipboardService.swift     # Clipboard operations
│
├── Views/
│   ├── ContentView.swift          # Main history view
│   ├── SettingsView.swift         # Settings panel
│   ├── RecordingIndicatorView.swift  # Visual recording feedback
│   └── TranscriptionRow.swift     # History list item
│
└── Assets.xcassets/               # App icons, colors
```

---

## Progress Tracking

- [x] Phase 0: Project Setup (partial)
- [ ] Phase 1: Audio Recording
- [ ] Phase 2: Global Hotkey Monitoring
- [ ] Phase 3: Whisper API Integration
- [ ] Phase 4: Data Models & Persistence
- [ ] Phase 5: Text Output (Clipboard)
- [ ] Phase 6: Main UI - History View
- [ ] Phase 7: Settings View
- [ ] Phase 8: Integration & Polish

---

## Next Steps

1. Complete Phase 0 (project setup)
2. Start Phase 1 (audio recording)
3. Test each phase thoroughly before moving to next
4. Iterate on UX after MVP is functional

---

Last Updated: 2025-10-16

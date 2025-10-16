# Aural V2 - Feature Roadmap

## Overview
Version 2 focuses on improved UX, cost optimization, and advanced recording modes inspired by Whispr Flow and WhatsApp.

---

## V2 Features

### 1. Floating Widget (Wispr Flow Style)

**Goal:** Always-visible recording status that doesn't interrupt workflow

**Design:**
- Small floating window that stays on top of all apps
- Shows current state: Idle / Recording / Transcribing
- Animated visual feedback (waveform during recording, spinner during transcription)
- Minimal and unobtrusive design
- Draggable to reposition
- Option to hide/show via menu bar

**Technical Approach:**
- Create `NSPanel` with `.nonactivatingPanel` level
- Use `.floating` window level to stay on top
- SwiftUI view embedded in NSHostingView
- Auto-hide when idle (optional preference)
- Smooth animations with SwiftUI

**Implementation:**
```
Views/FloatingWidget.swift
  - FloatingWidgetView (SwiftUI)
  - FloatingWidgetController (NSPanel wrapper)
  - Waveform visualization component
  - Transcription progress indicator
```

**User Preferences:**
- Enable/disable floating widget
- Widget position (saves last position)
- Widget size (small/medium/large)
- Auto-hide when idle

---

### 2. Direct Text Injection at Cursor

**Goal:** Type transcription directly where user is focused instead of clipboard

**Technical Approach:**
- Use Accessibility API (`CGEvent.tapCreate`)
- Simulate keyboard input with `CGEventCreateKeyboardEvent`
- Character-by-character typing or paste simulation
- Detect active text field via accessibility

**Implementation:**
```
Services/TextInjector.swift
  - getActiveApplication() -> NSRunningApplication?
  - getFocusedElement() -> AXUIElement?
  - injectText(text: String)
  - simulateKeyPress(character: Character)
```

**Fallback:**
- If text injection fails → copy to clipboard (current behavior)
- Show notification indicating which method was used

**User Preferences:**
- Text injection mode: Auto / Clipboard / Always Inject
- Typing speed (instant vs. simulated typing)

**Considerations:**
- Requires accessibility permissions (already needed for hotkey)
- May not work in all apps (password fields, some secure inputs)
- Need to preserve cursor position

---

### 3. Audio Speed-Up for Cost Savings

**Goal:** Speed up audio 1.5x-2x before sending to Whisper to reduce API costs

**Why This Works:**
- Whisper API charges per second of audio
- Speeding up audio reduces duration → reduces cost
- Whisper handles sped-up audio well (designed for it)
- 1.5x-2x is optimal (maintains quality, saves ~33-50%)

**Technical Approach:**

**Option A: AVAudioEngine (Native, Preferred)**
```swift
let audioEngine = AVAudioEngine()
let timePitch = AVAudioUnitTimePitch()
timePitch.rate = 1.5 // Speed up 1.5x
audioEngine.attach(timePitch)
```

**Option B: FFmpeg (More control, requires binary)**
```bash
ffmpeg -i input.m4a -filter:a "atempo=1.5" output.m4a
```

**Implementation:**
```
Services/AudioProcessor.swift
  - speedUpAudio(url: URL, rate: Float) -> URL
  - Options: AVAudioEngine or FFmpeg integration

Settings:
  - Speed multiplier: 1.0x (off) / 1.25x / 1.5x / 2.0x
  - Show estimated cost savings
```

**User Preferences:**
- Audio speed multiplier dropdown
- Show "Estimated savings: X%" based on average recording length
- Option to preview sped-up audio before sending

**Cost Calculation:**
- Track total seconds recorded
- Show: "Original: $X.XX | With 1.5x: $Y.YY | Saved: $Z.ZZ"

---

### 4. Audio Feedback (Sounds)

**Goal:** Haptic/audio feedback for better UX without looking at screen

**Sounds Needed:**
1. **Recording Started** - Short "beep" or "click"
2. **Recording Stopped** - Different "beep" (confirmation)
3. **Transcription Complete** - Success chime
4. **Error** - Alert sound

**Technical Approach:**
- Use `NSSound` for macOS system sounds
- Bundle custom sounds in Assets or use system sounds
- Respect system sound preferences

**Implementation:**
```
Services/SoundPlayer.swift
  - playRecordingStart()
  - playRecordingStop()
  - playTranscriptionComplete()
  - playError()

Assets:
  - recording_start.aiff
  - recording_stop.aiff
  - transcription_complete.aiff
  - error.aiff
```

**User Preferences:**
- Enable/disable sounds
- Volume level
- Choose sound theme (minimal/classic/fun)

---

### 5. Advanced Recording Modes (WhatsApp-Style)

**Goal:** Flexible recording with hold-to-record and lock modes

#### Mode 1: Hold-to-Record (Current Behavior)
- Hold Fn → Recording
- Release Fn → Stop & Transcribe
- **Default mode**

#### Mode 2: Tap-to-Lock Recording
- **Quick tap** (< 0.3s) → Start recording (locked)
- **Tap again** → Stop & Transcribe
- **Visual indicator**: Locked recording state
- Like WhatsApp "slide to cancel" but with tap

#### Mode 3: Hybrid (Smart Mode)
- **Hold** (> 0.5s) → Recording while held
- **Quick tap** → Toggle lock recording
- **Hold while locked** → Cancel recording (slide to cancel)

**Implementation:**
```
Services/HotkeyMonitor.swift enhancements:
  - Track key press duration
  - Detect quick tap vs. hold
  - Add recordingMode: .hold / .tapToLock / .hybrid

Models/RecordingMode.swift:
  enum RecordingMode {
    case holdOnly
    case tapToLock
    case hybrid
  }

State Management:
  - isRecordingLocked: Bool
  - keyPressStartTime: Date?
  - Quick tap threshold: 0.3s
```

**UI Indicators:**
```
FloatingWidget states:
  - Recording (held) → Pulsing red + "Release to stop"
  - Recording (locked) → Solid red + "Tap to stop"
  - Transcribing → Blue spinner + "Transcribing..."
```

**User Preferences:**
- Recording mode: Hold / Tap-to-Lock / Hybrid
- Quick tap threshold (ms)
- Visual/audio feedback for mode switches

---

## Implementation Plan

### Phase 1: Floating Widget (High Impact)
**Priority:** HIGH
**Complexity:** Medium
**Time Estimate:** 3-4 hours

**Tasks:**
1. Create NSPanel-based floating window
2. Design minimal UI (idle/recording/transcribing states)
3. Add waveform visualization during recording
4. Make draggable and remember position
5. Integrate with existing AppState

**Files to Create:**
- `Views/FloatingWidget/FloatingWidgetView.swift`
- `Views/FloatingWidget/FloatingWidgetController.swift`
- `Views/FloatingWidget/WaveformView.swift`

**Files to Modify:**
- `Models/AppState.swift` (add widget state)
- `AuralApp.swift` (initialize floating window)

---

### Phase 2: Recording Modes (Quick Win)
**Priority:** HIGH
**Complexity:** Low-Medium
**Time Estimate:** 2-3 hours

**Tasks:**
1. Enhance HotkeyMonitor to track key press duration
2. Implement tap-to-lock logic
3. Add recording mode preference
4. Update UI to show locked state
5. Add visual feedback for mode transitions

**Files to Create:**
- `Models/RecordingMode.swift`

**Files to Modify:**
- `Services/HotkeyMonitor.swift`
- `Models/AppState.swift`
- `Views/RecordingIndicatorView.swift`
- `Views/SettingsView.swift`

---

### Phase 3: Audio Feedback (Quick Win)
**Priority:** MEDIUM
**Complexity:** Low
**Time Estimate:** 1-2 hours

**Tasks:**
1. Create SoundPlayer service
2. Add sound assets or use system sounds
3. Integrate at key points (start/stop/complete/error)
4. Add preference toggles

**Files to Create:**
- `Services/SoundPlayer.swift`
- Sound assets in Assets.xcassets

**Files to Modify:**
- `Models/AppState.swift` (trigger sounds)
- `Views/SettingsView.swift` (sound preferences)

---

### Phase 4: Text Injection (High Value)
**Priority:** HIGH
**Complexity:** High
**Time Estimate:** 4-5 hours

**Tasks:**
1. Create TextInjector service using Accessibility API
2. Implement app/element detection
3. Add keyboard event simulation
4. Test across different apps (TextEdit, Chrome, Slack, etc.)
5. Add fallback to clipboard
6. Add preference toggle

**Files to Create:**
- `Services/TextInjector.swift`

**Files to Modify:**
- `Models/AppState.swift`
- `Views/SettingsView.swift`

**Testing Apps:**
- TextEdit
- Notes
- Chrome/Safari
- Slack
- VS Code
- Terminal

---

### Phase 5: Audio Speed-Up (Cost Optimization)
**Priority:** MEDIUM
**Complexity:** Medium
**Time Estimate:** 3-4 hours

**Tasks:**
1. Create AudioProcessor service
2. Implement speed-up using AVAudioEngine
3. Test quality at different speeds (1.25x, 1.5x, 2.0x)
4. Add preference slider
5. Calculate and display cost savings
6. Optional: Add FFmpeg fallback for more control

**Files to Create:**
- `Services/AudioProcessor.swift`

**Files to Modify:**
- `Models/AppState.swift`
- `Services/WhisperService.swift`
- `Views/SettingsView.swift`

**Considerations:**
- Test Whisper quality with sped-up audio
- Some voices may not work well at 2x
- Add "Test with current speed" button

---

## Settings Mockup (V2)

```
Settings
├── General
│   ├── Recording Mode: [Hold / Tap-to-Lock / Hybrid]
│   ├── Quick tap threshold: [300ms slider]
│   └── Show floating widget: [✓]
│
├── Audio
│   ├── Speed multiplier: [1.0x / 1.25x / 1.5x / 2.0x]
│   ├── Enable sounds: [✓]
│   ├── Sound volume: [slider]
│   └── Test audio speed (button)
│
├── Transcription
│   ├── Text output: [Auto / Clipboard / Direct Injection]
│   ├── Typing speed: [Instant / Natural]
│   └── API Key: [secure field]
│
├── Widget
│   ├── Show waveform: [✓]
│   ├── Widget size: [Small / Medium / Large]
│   ├── Auto-hide when idle: [✓]
│   └── Auto-hide delay: [5s slider]
│
└── Advanced
    ├── Show cost statistics: [✓]
    ├── Total seconds recorded: 1,234s
    ├── Estimated cost: $0.12
    └── Savings with 1.5x: $0.04 (33%)
```

---

## UI/UX Improvements (V2)

### Main Window Improvements

**Fixed Window Size:**
- Prevent full-screen mode (not appropriate for this app type)
- Set min/max size constraints
- Disable window zoom button
- More compact, focused layout

**Friendlier UI:**
- Softer colors, rounded corners
- Better spacing and padding
- Clearer visual hierarchy
- Modern macOS Big Sur+ style
- Dark mode support
- Subtle animations and transitions

**Implementation:**
```swift
WindowGroup {
    ContentView()
}
.windowStyle(.hiddenTitleBar) // Cleaner look
.windowResizability(.contentSize) // Fixed size
.defaultSize(width: 500, height: 600)
```

### Floating Widget States

**Idle State:**
```
┌─────────────────┐
│  🎤  Aural      │
│  Ready          │
└─────────────────┘
```

**Recording (Hold):**
```
┌─────────────────┐
│  ⏺  Recording   │
│  ▓▓▒▒░░  0:03   │
│  Release to stop│
└─────────────────┘
```

**Recording (Locked):**
```
┌─────────────────┐
│  ⏺🔒 Recording  │
│  ▓▓▒▒░░  0:15   │
│  Tap to stop    │
└─────────────────┘
```

**Transcribing:**
```
┌─────────────────┐
│  ⌛ Transcribing│
│  ◐ Please wait  │
└─────────────────┘
```

**Success:**
```
┌─────────────────┐
│  ✓  Complete!   │
│  "Hello world"  │
└─────────────────┘
```

---

## Technical Considerations

### Text Injection Challenges
- **Security:** Some apps block programmatic typing (password fields)
- **Permissions:** Need accessibility access (already required)
- **Reliability:** Different apps handle events differently
- **Testing:** Need to test across many apps

**Solution:** Graceful fallback to clipboard with notification

### Audio Speed-Up Quality
- **Risk:** Too fast = poor transcription
- **Mitigation:** Test Whisper accuracy at each speed
- **Recommendation:** Default to 1.5x, allow user to adjust
- **A/B Testing:** Let users compare quality/cost

### Floating Widget Performance
- **Risk:** Waveform animation could use CPU
- **Mitigation:** Use efficient Core Animation or Metal
- **Optimization:** Only animate when visible
- **Battery:** Monitor energy impact

### Recording Mode Complexity
- **Risk:** Confusing for users
- **Mitigation:** Clear UI feedback, good defaults
- **Onboarding:** Show quick tutorial on first launch
- **Recommendation:** Default to "Hybrid" mode (best of both)

---

## Success Metrics (V2)

**User Experience:**
- Recording starts < 100ms after key press
- Floating widget FPS > 30
- Text injection success rate > 90%
- User satisfaction with recording modes

**Cost Savings:**
- Average cost reduction with 1.5x: ~33%
- User adoption of speed-up feature: target 60%+

**Reliability:**
- Crash-free rate: 99%+
- Permission grant rate: 95%+
- Transcription accuracy: maintained with speed-up

---

## Phased Rollout

### V2.0 (Essential Features)
- ✅ Floating widget
- ✅ Recording modes (all three)
- ✅ Audio feedback sounds

### V2.1 (Advanced)
- ✅ Text injection
- ✅ Audio speed-up

### V2.2 (Polish)
- Cost statistics dashboard
- Tutorial/onboarding
- Keyboard shortcuts for all actions
- Custom themes for widget

---

## Open Questions

1. **Floating Widget Design:**
   - Should it be circular or rectangular?
   - Dark mode support?
   - Custom colors/themes?

2. **Text Injection:**
   - Should we preserve formatting (bold, italic, etc.)?
   - Support for markdown conversion?
   - Auto-capitalization?

3. **Recording Modes:**
   - Should "hold" mode have a max duration limit?
   - Visual indicator when approaching limit?
   - Auto-stop after X minutes?

4. **Audio Speed-Up:**
   - Should we bundle FFmpeg or use native AVAudioEngine?
   - Preview sped-up audio before sending?
   - Per-language speed recommendations?

5. **Menu Bar:**
   - Should main window be hideable?
   - Menu bar only mode?
   - Quick actions from menu bar?

---

## Next Steps

**Immediate:**
1. Get V1 working (finish permission setup)
2. Test end-to-end flow
3. Gather user feedback

**V2 Development Order (Recommended):**
1. **Phase 2** (Recording Modes) - Quick win, big UX improvement
2. **Phase 3** (Audio Feedback) - Quick win, complements recording modes
3. **Phase 1** (Floating Widget) - Most visible feature
4. **Phase 5** (Audio Speed-Up) - Cost savings
5. **Phase 4** (Text Injection) - Most complex, test thoroughly

**Timeline Estimate:**
- All V2 features: ~15-20 hours
- Phased rollout: 1-2 weeks of development
- Testing & polish: 1 week

---

Last Updated: 2025-10-16

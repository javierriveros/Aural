# Feature Roadmap - Aural

## Current Features (V2) ✅

- ✅ Three recording modes (hold, tap-to-lock, hybrid)
- ✅ Global Fn key hotkey
- ✅ OpenAI Whisper transcription
- ✅ Text injection at cursor
- ✅ Clipboard fallback
- ✅ Floating widget
- ✅ Audio speed-up (cost optimization)
- ✅ Audio feedback sounds
- ✅ Transcription history
- ✅ Settings management

---

## 🎯 Essential Features for Production

### 1. Custom Hotkey Configuration
**Why**: Fn key doesn't work for everyone (Windows keyboards, conflicts)
**Impact**: HIGH - Critical for usability

**Implementation**:
```swift
class HotkeyRecorder: NSView {
    func recordHotkey() -> KeyCombination
}

struct HotkeySettings {
    var modifiers: NSEvent.ModifierFlags
    var keyCode: UInt16
}
```

**Features**:
- Record custom hotkey combinations
- Support Cmd/Opt/Ctrl/Shift combinations
- Conflict detection with system shortcuts
- Multiple hotkey profiles (global, app-specific)

**UI**:
- "Record Hotkey" button in settings
- Visual feedback during recording
- Clear/reset option

---

### 2. Enhanced Language Support
**Why**: Compete globally, not just English
**Impact**: HIGH - Market expansion

**Features**:
- Detect language automatically
- Manual language selection
- Multi-language support in single recording
- Language-specific models (if available)

**Implementation**:
```swift
enum TranscriptionLanguage: String, CaseIterable {
    case auto = "Auto-detect"
    case english = "English"
    case spanish = "Spanish"
    case french = "French"
    case german = "German"
    case chinese = "Chinese"
    // ... 90+ languages Whisper supports
}

// In WhisperService
func transcribe(audioURL: URL, language: TranscriptionLanguage?) async throws -> String
```

---

### 3. Custom Vocabulary / Personal Dictionary
**Why**: Technical terms, names, acronyms often misspelled
**Impact**: MEDIUM-HIGH - Professional use case

**Features**:
- Add custom words/phrases
- Phonetic spelling hints
- Auto-replacement rules
- Import/export dictionary

**Implementation**:
```swift
struct CustomVocabulary {
    var words: [String: String] // "Jay-vee-err" -> "Javier"
    var phrases: [String: String]
    var acronyms: [String: String]
}

class VocabularyService {
    func applyReplacements(to text: String) -> String
}
```

**UI**:
- Dictionary management in settings
- Quick add from transcription history
- Suggestions for commonly mis-transcribed words

---

### 4. Transcription Commands
**Why**: Voice-driven formatting, no keyboard needed
**Impact**: MEDIUM - Power user feature

**Features**:
- Punctuation: "comma", "period", "question mark"
- Formatting: "new line", "new paragraph", "tab"
- Capitalization: "cap that", "all caps", "lowercase"
- Editing: "delete that", "scratch that", "undo"
- Special: "smiley face", "copyright symbol"

**Implementation**:
```swift
class CommandProcessor {
    let commands: [String: Command] = [
        "comma": .insertPunctuation(","),
        "period": .insertPunctuation("."),
        "new line": .insertSpecial("\n"),
        "cap that": .capitalizeLastWord,
        "delete that": .deleteLastWord
    ]

    func processCommands(in text: String) -> String
}
```

---

### 5. Search & Filter History
**Why**: Finding old transcriptions is painful
**Impact**: MEDIUM - Quality of life

**Features**:
- Full-text search
- Filter by date range
- Filter by duration
- Sort options (date, length, alphabetical)
- Favorites/starred transcriptions
- Tags/categories

**Implementation**:
```swift
@Query(
    filter: #Predicate<Transcription> { $0.text.contains(searchText) },
    sort: [SortDescriptor(\Transcription.timestamp, order: .reverse)]
)
var filteredTranscriptions: [Transcription]
```

**UI**:
- Search bar in history view
- Filter chips/buttons
- Quick actions (star, tag, export)

---

### 6. Export & Backup
**Why**: Data portability, safety
**Impact**: MEDIUM - Professional requirement

**Features**:
- Export formats: TXT, JSON, CSV, Markdown
- Batch export (all/selected)
- Automatic backups (iCloud, local)
- Import from backup
- Sync across devices

**Implementation**:
```swift
enum ExportFormat {
    case plainText, json, csv, markdown
}

class ExportService {
    func export(_ transcriptions: [Transcription],
                format: ExportFormat) -> Data

    func importBackup(from url: URL) throws -> [Transcription]
}
```

---

### 7. Privacy & Local Processing
**Why**: Enterprise users, privacy-conscious users
**Impact**: HIGH - Competitive differentiator

**Features**:
- Local Whisper model option (CoreML)
- No data sent to cloud
- Automatic deletion after X days
- Encrypted storage
- Privacy mode (no history saving)

**Implementation**:
```swift
enum TranscriptionProvider {
    case openAI(apiKey: String)
    case localWhisper(modelPath: URL)
    case azure(endpoint: String, key: String)
}

class LocalWhisperService {
    private let model: WhisperModel // CoreML model

    func transcribe(audioURL: URL) async throws -> String {
        // Runs entirely on-device
    }
}
```

**Considerations**:
- Model size: ~1-3GB depending on variant
- Performance: Slower than cloud but private
- Download models from Hugging Face
- Cache models locally

---

### 8. Advanced Text Formatting
**Why**: Clean output without manual editing
**Impact**: MEDIUM - Quality of life

**Features**:
- Auto-capitalize sentences
- Smart quotes ("" vs '')
- Remove filler words (um, uh, like)
- Number formatting (1,000 vs one thousand)
- Auto-correct common mistakes
- Grammar suggestions

**Implementation**:
```swift
class TextFormatter {
    var autoCapitalize: Bool = true
    var smartQuotes: Bool = true
    var removeFillers: Bool = true
    var numberStyle: NumberStyle = .digits

    func format(_ text: String) -> String
}
```

---

### 9. Keyboard Shortcuts & Power User Features
**Why**: Efficiency for frequent users
**Impact**: MEDIUM - User retention

**Features**:
- Keyboard shortcuts for all actions
- Quick record (without opening app)
- Re-transcribe last recording
- Copy last transcription
- Open history
- Toggle widget visibility

**Implementation**:
```swift
enum AppShortcut: String {
    case quickRecord = "cmd+shift+R"
    case copyLast = "cmd+shift+C"
    case openHistory = "cmd+shift+H"
    case retranscribe = "cmd+shift+T"
}

class ShortcutManager {
    func registerShortcuts()
    func handleShortcut(_ shortcut: AppShortcut)
}
```

---

### 10. Statistics & Analytics
**Why**: Usage insights, cost tracking
**Impact**: LOW-MEDIUM - Nice to have

**Features**:
- Total transcriptions count
- Total duration recorded
- Average transcription length
- API cost tracking
- Usage graphs (daily/weekly/monthly)
- Most used times of day
- Savings from speed-up

**Implementation**:
```swift
struct UsageStats {
    var totalTranscriptions: Int
    var totalDuration: TimeInterval
    var totalCost: Decimal
    var avgTranscriptionLength: Int
    var costSavingsFromSpeedUp: Decimal

    func weeklyUsage() -> [Date: Int]
}
```

**UI**:
- Dashboard tab/section
- Charts with Swift Charts
- Export stats as CSV

---

## 🚀 Advanced Features (V3+)

### 11. Real-Time Transcription (Streaming)
**Why**: See words as you speak
**Impact**: MEDIUM - Cool factor, but complex

**Features**:
- Live transcription during recording
- Word-by-word appearance
- Partial results shown immediately
- Final result replaces partial

**Challenges**:
- OpenAI Whisper doesn't support streaming natively
- Would need alternative provider (Google, Azure)
- Or use local streaming model

**Alternatives**:
- Apple Speech framework for real-time
- Then send to Whisper for accuracy correction

---

### 12. Templates & Snippets
**Why**: Common formats (emails, reports)
**Impact**: MEDIUM - Productivity boost

**Features**:
- Pre-defined templates
- Variable placeholders
- Quick insertion
- Custom templates

**Example**:
```
Template: "Email to {{recipient}}"
Content: "Hi {{recipient}},\n\n{{transcription}}\n\nBest regards,\n{{sender}}"
```

---

### 13. Integration Hub
**Why**: Workflows, automation
**Impact**: MEDIUM-HIGH - Power users

**Features**:
- Shortcuts.app integration
- AppleScript support
- URL scheme (`aural://record`)
- Webhooks (send to Slack, Notion, etc.)
- Alfred/Raycast plugin
- CLI tool

**Implementation**:
```swift
// URL Scheme
enum AuralURLAction {
    case record
    case copyLast
    case openHistory

    static func handle(url: URL)
}

// Shortcuts
struct RecordVoiceIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Voice"

    func perform() async throws -> String {
        // Record and return transcription
    }
}
```

---

### 14. Multi-Speaker Diarization
**Why**: Meetings, interviews
**Impact**: LOW-MEDIUM - Niche but valuable

**Features**:
- Detect multiple speakers
- Label speakers (Speaker 1, 2, etc.)
- Assign names to speakers
- Export with speaker labels

**Implementation**:
- Requires specialized model (pyannote.audio)
- Or use Whisper with additional processing
- More complex, V3+ feature

---

### 15. Translation
**Why**: International users
**Impact**: MEDIUM - Market expansion

**Features**:
- Transcribe in one language
- Translate to another
- Multiple target languages
- Preserve formatting

**Implementation**:
```swift
class TranslationService {
    func translate(_ text: String,
                   from: Language,
                   to: Language) async throws -> String
}
```

**Options**:
- OpenAI GPT for translation (costs more)
- Google Translate API
- Apple's built-in Translation framework

---

### 16. AI Enhancement
**Why**: Better than raw transcription
**Impact**: MEDIUM-HIGH - Differentiation

**Features**:
- Grammar correction
- Punctuation improvement
- Formatting enhancement
- Summarization
- Action item extraction
- Key points extraction

**Implementation**:
```swift
class AIEnhancer {
    func enhance(_ text: String,
                 mode: EnhancementMode) async throws -> String
}

enum EnhancementMode {
    case grammarOnly
    case fullEnhancement
    case summarize
    case extractActionItems
}
```

**Using GPT-4**:
```swift
let prompt = """
Fix grammar and punctuation in this transcription,
but keep the original meaning:

\(rawTranscription)
"""
```

---

### 17. Team Features (Enterprise)
**Why**: Company-wide adoption
**Impact**: HIGH - Revenue opportunity

**Features**:
- Team accounts
- Shared vocabulary
- Usage quotas
- Admin dashboard
- SSO (Single Sign-On)
- Audit logs
- Cost allocation

**Implementation**:
- Backend service required
- User authentication
- Team management
- Billing integration

---

### 18. Smart Detection & Auto-Actions
**Why**: Automation, less manual work
**Impact**: MEDIUM - Convenience

**Features**:
- Detect email dictation → format as email
- Detect code dictation → format as code
- Detect URLs → make clickable
- Detect phone numbers → format
- Detect dates/times → calendar events
- Auto-tag by content

**Implementation**:
```swift
class SmartDetector {
    func detect(in text: String) -> [Detection]
}

enum Detection {
    case email(String)
    case url(String)
    case phoneNumber(String)
    case date(Date)
    case code(language: String, content: String)
}
```

---

### 19. Quality Indicators
**Why**: Know when to re-record
**Impact**: LOW-MEDIUM - User confidence

**Features**:
- Confidence score for transcription
- Audio quality indicator
- Background noise level
- Suggested improvements
- Warning for low confidence

**Implementation**:
```swift
struct TranscriptionQuality {
    var confidenceScore: Double // 0.0 - 1.0
    var audioQuality: AudioQuality
    var backgroundNoiseLevel: Double
    var suggestions: [String]
}
```

---

### 20. Advanced Widget Options
**Why**: Customization
**Impact**: LOW - Polish

**Features**:
- Widget size options (small/medium/large)
- Widget position (corners, edges)
- Transparency level
- Always on top toggle
- Hide when not recording
- Custom colors/themes

---

## 📊 Feature Priority Matrix

### Must Have (Next Release)
1. **Custom Hotkey** - Critical for adoption
2. **Language Support** - Market expansion
3. **Search & Filter** - Basic necessity
4. **Export/Backup** - Data safety
5. **Custom Vocabulary** - Professional use

### Should Have (Near Future)
6. **Voice Commands** - Power user feature
7. **Text Formatting** - Quality improvement
8. **Keyboard Shortcuts** - Efficiency
9. **Statistics** - User engagement
10. **Privacy/Local Mode** - Differentiator

### Could Have (Future)
11. **Templates** - Productivity boost
12. **Integration Hub** - Ecosystem play
13. **AI Enhancement** - Premium feature
14. **Real-time Transcription** - Cool factor
15. **Translation** - International

### Won't Have (Maybe Never)
16. **Speaker Diarization** - Too niche
17. **Team Features** - Requires infrastructure
18. **Advanced Analytics** - Over-engineering

---

## 💰 Monetization Features

### Free Tier
- Basic transcription (BYO API key)
- Local history (last 30 days)
- Standard hotkey
- Basic export

### Pro Tier ($5-10/month)
- Unlimited history
- Cloud sync
- Custom vocabulary
- Advanced formatting
- Priority support
- No ads

### Team Tier ($20-30/user/month)
- Everything in Pro
- Team vocabulary
- Usage analytics
- Admin controls
- SSO support
- Dedicated support

### One-Time Purchase ($30-50)
- Everything except:
  - Cloud sync (optional subscription)
  - Team features
  - AI enhancements (requires ongoing costs)

---

## 🎨 UX/Polish Features

### Onboarding
- Welcome screen
- Permission requests with explanations
- Quick tutorial
- Sample recording
- Best practices tips

### First-Run Experience
- Auto-detect optimal settings
- Microphone test
- API key validation
- Hotkey setup wizard

### Error Messages
- Clear, actionable errors
- Recovery suggestions
- Help links
- Support contact

### Accessibility
- VoiceOver support
- Keyboard navigation
- High contrast mode
- Reduced motion option
- Screen reader optimized

### Performance
- Launch time < 1 second
- Recording starts instantly
- Transcription progress indicator
- Background processing
- Low memory footprint

---

## 🏆 Competitive Analysis

### vs. Wispr Flow
**They have**:
- Real-time transcription
- Multiple providers
- Better UI/UX
- Team features

**We can add**:
- Local processing (privacy)
- Custom vocabulary
- More integrations
- Lower cost (user's API key)

### vs. SuperWhisper
**They have**:
- Local models
- No subscription
- Fast processing

**We can add**:
- Cloud option (accuracy)
- History sync
- AI enhancements
- Better customization

### Unique Selling Points
1. **Privacy-first**: Local + cloud options
2. **Bring your own key**: Lower cost
3. **Open source**: Community trust
4. **Customizable**: Ultimate flexibility
5. **Integration-friendly**: Shortcuts, CLI, webhooks

---

## 📝 Implementation Roadmap

### Phase 1: Foundation (Current) ✅
- [x] Core recording
- [x] Transcription
- [x] Basic UI
- [x] History

### Phase 2: Essential (Next 2-4 weeks)
- [ ] Custom hotkey
- [ ] Language support
- [ ] Search & filter
- [ ] Export/backup
- [ ] Custom vocabulary

### Phase 3: Professional (1-2 months)
- [ ] Voice commands
- [ ] Text formatting
- [ ] Keyboard shortcuts
- [ ] Statistics
- [ ] Local processing option

### Phase 4: Advanced (2-3 months)
- [ ] Templates
- [ ] Integrations
- [ ] AI enhancements
- [ ] Real-time (maybe)
- [ ] Translation

### Phase 5: Scale (3-6 months)
- [ ] Team features
- [ ] Cloud sync
- [ ] Mobile app
- [ ] Web dashboard

---

## 🎯 Success Metrics

### User Acquisition
- Downloads: 1,000 in first month
- Active users: 500 DAU
- Retention: 40% week 1

### Engagement
- Avg transcriptions/day: 5-10
- Session length: 2-3 minutes
- Return rate: 3x/week

### Quality
- Crash rate: < 0.1%
- Error rate: < 1%
- Average rating: > 4.5 stars

### Revenue (if monetized)
- Conversion rate: 2-5%
- MRR: $1,000 in 3 months
- LTV: $60-100

---

## 🚢 Launch Checklist

### Pre-Launch
- [ ] Feature complete (Phase 2)
- [ ] Bug-free core functionality
- [ ] Performance optimized
- [ ] Security audit
- [ ] Legal review (terms, privacy)

### Documentation
- [ ] README with setup guide
- [ ] User documentation
- [ ] API documentation (if any)
- [ ] Troubleshooting guide
- [ ] FAQ

### Marketing
- [ ] Product Hunt launch
- [ ] Twitter announcement
- [ ] Blog post
- [ ] Demo video
- [ ] Screenshots/GIFs

### Distribution
- [ ] Mac App Store submission
- [ ] Homebrew formula
- [ ] Direct download (GitHub)
- [ ] Auto-update system

### Support
- [ ] Discord/Slack community
- [ ] GitHub discussions
- [ ] Email support
- [ ] Bug reporting system

---

## Summary

To make Aural production-ready and competitive:

**Essential (Do First)**:
1. Custom hotkey configuration
2. Multi-language support
3. Search & filter history
4. Export/backup system
5. Custom vocabulary

**High Impact**:
6. Voice commands for formatting
7. Local processing option (privacy)
8. Keyboard shortcuts
9. Text formatting enhancements
10. Statistics dashboard

**Differentiators**:
11. Open source + privacy-first
12. Bring your own API key
13. Extensive integrations
14. AI enhancements (GPT)
15. Ultimate customization

With these features, Aural would be a **best-in-class** voice dictation app that competes with or exceeds commercial alternatives!

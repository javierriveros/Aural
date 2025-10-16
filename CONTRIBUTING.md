# Contributing to Aural

Thank you for considering contributing to Aural! We welcome contributions from everyone and appreciate your help making this project better.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Features](#suggesting-features)
  - [Code Contributions](#code-contributions)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)

---

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

---

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report, please check the existing issues to avoid duplicates.

**When filing a bug report, include:**
- **Clear, descriptive title** - Use a title that clearly identifies the issue
- **Steps to reproduce** - Detailed steps to reproduce the behavior
- **Expected behavior** - What you expected to happen
- **Actual behavior** - What actually happened
- **Screenshots** - If applicable, add screenshots
- **Environment**:
  - macOS version (e.g., macOS 14.2)
  - Aural version (from About section)
  - Xcode version (if building from source)
- **Logs** - Check Console.app for relevant error messages

**Example:**
```
Title: Recording fails with "Audio engine initialization failed" error

Steps to reproduce:
1. Launch Aural
2. Grant microphone permissions
3. Press Fn key to record
4. Error appears immediately

Expected: Recording should start
Actual: Error message "Audio engine initialization failed"

Environment:
- macOS 14.2 (23C64)
- Aural 1.0.0
- Built from source with Xcode 15.2
```

### Suggesting Features

Feature suggestions are welcome! Before creating a suggestion:
- Check if the feature already exists in the latest version
- Search existing issues to avoid duplicates
- Consider if it aligns with the project's goals

**When suggesting a feature, include:**
- **Clear use case** - Why is this feature needed?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you think about?
- **Additional context** - Screenshots, mockups, examples

### Code Contributions

We love code contributions! Here's how to get started:

1. **Find an issue** - Look for issues labeled `good first issue` or `help wanted`
2. **Ask to be assigned** - Comment on the issue to avoid duplicate work
3. **Fork the repository** - Create your own fork
4. **Create a branch** - Name it descriptively (e.g., `feature/custom-hotkeys` or `fix/memory-leak`)
5. **Make your changes** - Follow the coding guidelines below
6. **Test thoroughly** - Ensure nothing breaks
7. **Submit a PR** - Follow the pull request process below

---

## Development Setup

### Prerequisites
- macOS 14.0+ (Sonoma or later)
- Xcode 15+ with Command Line Tools
- OpenAI API key (for testing transcription)

### Setup Steps

1. **Fork and clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/aural.git
   cd aural
   ```

2. **Open in Xcode**
   ```bash
   open Aural.xcodeproj
   ```

3. **Configure signing**
   - Select the Aural target
   - Go to "Signing & Capabilities"
   - Select your development team

4. **Build and run**
   - Press `⌘R` or click Run
   - Grant necessary permissions when prompted

5. **Add API key for testing**
   - Run the app
   - Open Settings
   - Add your OpenAI API key

---

## Coding Guidelines

### Swift Style

We follow standard Swift conventions with some additions:

#### General
- **No force unwraps** - Use safe optional binding (`guard let`, `if let`)
- **Explicit types** - Use type inference, but be explicit when it improves clarity
- **Use `let` by default** - Only use `var` when mutation is needed
- **Prefer `guard` for early returns** - Makes code flow clearer

#### SwiftUI
- **Use `@Observable`** for state management (not `@StateObject` / `@ObservedObject`)
- **Extract reusable views** - Keep views under ~100 lines
- **Use design system** - Reference `DesignSystem.swift` for colors, spacing, fonts
- **Prefer async/await** - Use modern concurrency over callbacks

#### Naming
- **Descriptive names** - Clarity over brevity
- **Verb methods** - `startRecording()` not `recording()`
- **Bool properties** - Prefix with `is`, `has`, `should` (e.g., `isRecording`)
- **Services** - Suffix with `Service` (e.g., `WhisperService`)

#### Example
```swift
// ✅ Good
func processTranscription(_ text: String) async throws -> String {
    guard !text.isEmpty else {
        throw TranscriptionError.emptyText
    }

    let processed = vocabularyService.applyWordBoundaryReplacements(to: text)
    return voiceCommandProcessor.process(processed)
}

// ❌ Bad
func process(_ t: String) throws -> String {
    let p = vocab.apply(t)  // Unclear
    return vcProc.proc(p)!  // Force unwrap!
}
```

### Architecture

- **Services** - Business logic, stateless when possible
- **Models** - Data structures and @Observable state
- **Views** - UI only, minimal logic
- **Repositories** - Data persistence abstraction
- **Utilities** - Helper functions and extensions

### Error Handling

- **Use typed errors** - Create enums conforming to `LocalizedError`
- **Provide user-friendly messages** - Implement `errorDescription`
- **Handle all errors** - Never use `try?` without justification
- **Log errors** - Use `print()` for now (os.log planned)

#### Example
```swift
enum RecordingError: LocalizedError {
    case permissionDenied
    case audioEngineFailure
    case audioWriteFailure(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .audioEngineFailure:
            return "Audio engine initialization failed"
        case .audioWriteFailure(let error):
            return "Failed to write audio data: \(error.localizedDescription)"
        }
    }
}
```

### Memory Management

- **Use `[weak self]`** in closures that might outlive the owner
- **Implement `deinit`** for cleanup (timers, event monitors, etc.)
- **Clean up resources** - Remove temporary files, invalidate timers

### Testing

- **Manual testing** - Test all changes with real audio recording
- **Edge cases** - Test permission denied, network failures, etc.
- **Different modes** - Test all recording modes and features

---

## Commit Message Guidelines

We follow conventional commits for clear history:

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types
- **feat**: New feature
- **fix**: Bug fix
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **docs**: Documentation only
- **style**: Code style (formatting, missing semi-colons, etc.)
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples
```
feat(vocabulary): Add support for regex patterns

Users can now use regex patterns in custom vocabulary entries,
enabling more powerful text replacements.

Closes #42
```

```
fix(audio): Prevent memory leak in AudioRecorder

Timer was not being invalidated in all code paths, causing
instances to never deallocate.

- Add deinit to always stop timer
- Use [weak self] in timer closure
- Add proper cleanup on errors
```

```
refactor: Move API key to Keychain for security

BREAKING CHANGE: API keys now stored in Keychain instead of UserDefaults.
Existing keys will be migrated automatically on first launch.
```

---

## Pull Request Process

### Before Submitting

1. **Update from main**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-branch
   git rebase main
   ```

2. **Test thoroughly**
   - Build succeeds without warnings
   - All features work as expected
   - No regressions in existing functionality

3. **Self-review**
   - Read through your changes
   - Remove debug code and comments
   - Ensure code follows style guidelines

### PR Template

When creating a PR, include:

**Description**
- What does this PR do?
- Why is this change needed?

**Type of Change**
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

**Testing**
- How did you test this?
- What scenarios did you cover?

**Screenshots** (if applicable)

**Checklist**
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] No new warnings introduced
- [ ] Tested on macOS 14.0+
- [ ] Updated documentation if needed

### Review Process

1. **Automated checks** - CI will run (when configured)
2. **Maintainer review** - A maintainer will review your PR
3. **Changes requested** - Address feedback and push updates
4. **Approval** - Once approved, a maintainer will merge

### After Merge

- **Delete your branch** - Keep the repository clean
- **Update your fork**
  ```bash
  git checkout main
  git pull upstream main
  git push origin main
  ```

---

## Questions?

- **Check the docs** - README.md has extensive documentation
- **Search existing issues** - Your question might be answered
- **Ask in discussions** - GitHub Discussions for general questions
- **Open an issue** - For bugs or feature requests

---

Thank you for contributing to Aural! 🎤✨

# Linting Guide

Quick reference for linting and formatting Swift code in Aural.

## SwiftLint

### Installation

**Direct Download:**
```bash
cd /tmp && curl -L -o swiftlint.zip https://github.com/realm/SwiftLint/releases/download/0.62.1/portable_swiftlint.zip
unzip swiftlint.zip && mv swiftlint ~/.local/bin/swiftlint && chmod +x ~/.local/bin/swiftlint
```

### Usage

```bash
swiftlint              # Check for issues
swiftlint --fix        # Auto-fix issues
swiftlint lint file.swift  # Check specific file
```

### Xcode Integration

Add "Run Script Phase" to Build Phases:
```bash
if which swiftlint > /dev/null; then swiftlint; fi
```

## swift-format

Format code to Apple's Swift style guide:

```bash
swift-format format -r Aural/     # Format all files
swift-format lint Aural/          # Check without modifying
```

## Xcode Built-in

- Analyze: `⌘⇧B`
- Fix Issues: `⌃⌥⌘F`

## Common Issues

SwiftLint catches: force unwraps, unused code, complexity, style violations, potential bugs.

## Configuration

- `.swiftlint.yml` - Customize rules and thresholds
- Modify it to disable overly strict rules or adjust limits

## Resources

- [SwiftLint](https://github.com/realm/SwiftLint)
- [Swift Style Guide](https://swift.org/documentation/api-design-guidelines/)


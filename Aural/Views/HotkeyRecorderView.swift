import Carbon
import SwiftUI

// MARK: - Fn Conflict Row

struct FnConflictRow: View {
    let configuration: HotkeyConfiguration
    @State private var hasConflict = false

    var body: some View {
        Group {
            if hasConflict {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(BrandColors.warning)
                    Text("Set “Press 🌐 key to” to “Do Nothing” so Fn doesn't also open emoji or dictation.")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Open Keyboard Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
        .onAppear { hasConflict = configuration.hasFnSystemConflict }
        .onChange(of: configuration) { _, new in hasConflict = new.hasFnSystemConflict }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hasConflict = configuration.hasFnSystemConflict
        }
    }
}

// MARK: - Hotkey Recorder View

struct HotkeyRecorderView: View {
    @Binding var configuration: HotkeyConfiguration
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recording Hotkey:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if isRecording {
                    Text("Press any key combination...")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text(configuration.displayString)
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                }
            }

            HStack(spacing: 12) {
                Button(isRecording ? "Recording..." : "Record Hotkey") {
                    toggleRecording()
                }

                if configuration != .default {
                    Button("Reset to Default") {
                        configuration = .default
                    }
                }
            }

            Text("Click 'Record Hotkey' and press your desired key combination. Include modifier keys like ⌘, ⌥, ⌃, or ⇧.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear {
            setupEventMonitor()
        }
        .onDisappear {
            removeEventMonitor()
        }
    }

    private func toggleRecording() {
        isRecording.toggle()
    }

    private func setupEventMonitor() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [self] event in
            guard self.isRecording else { return event }

            let keyCode = CGKeyCode(event.keyCode)
            var modifiers: CGEventFlags = []

            if event.modifierFlags.contains(.command) {
                modifiers.insert(.maskCommand)
            }
            if event.modifierFlags.contains(.option) {
                modifiers.insert(.maskAlternate)
            }
            if event.modifierFlags.contains(.control) {
                modifiers.insert(.maskControl)
            }
            if event.modifierFlags.contains(.shift) {
                modifiers.insert(.maskShift)
            }
            if event.modifierFlags.contains(.function) {
                modifiers.insert(.maskSecondaryFn)
            }

            let isFunctionKey = keyCode >= 122 && keyCode <= 135
            if !modifiers.isEmpty || isFunctionKey {
                let newConfig = HotkeyConfiguration(keyCode: keyCode, modifiers: modifiers)

                DispatchQueue.main.async {
                    self.configuration = newConfig
                    self.isRecording = false
                }

                return nil
            }

            return event
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

#Preview {
    @Previewable @State var config = HotkeyConfiguration.default
    HotkeyRecorderView(configuration: $config)
        .padding()
        .frame(width: 400)
}

import SwiftUI
import Carbon

// MARK: - Hotkey Recorder View

struct HotkeyRecorderView: View {
    @Binding var configuration: HotkeyConfiguration
    @State private var isRecording = false
    @State private var recordedConfig: HotkeyConfiguration?

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
                    startRecording()
                }
                .disabled(isRecording)

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
    }

    private func startRecording() {
        isRecording = true
    }

    private func setupEventMonitor() {
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard isRecording else { return event }

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

            // Only accept if there's at least one modifier or it's a function key
            let isFunctionKey = keyCode >= 122 && keyCode <= 135
            if !modifiers.isEmpty || isFunctionKey {
                let newConfig = HotkeyConfiguration(keyCode: keyCode, modifiers: modifiers)
                configuration = newConfig
                isRecording = false
                return nil // Consume the event
            }

            return event
        }
    }
}

#Preview {
    @Previewable @State var config = HotkeyConfiguration.default
    HotkeyRecorderView(configuration: $config)
        .padding()
        .frame(width: 400)
}

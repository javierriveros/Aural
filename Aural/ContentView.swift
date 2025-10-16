//
//  ContentView.swift
//  Aural
//
//  Created by Javier Riveros on 16/10/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 20) {
            RecordingIndicatorView(
                isRecording: appState.audioRecorder.state == .recording,
                duration: appState.audioRecorder.recordingDuration
            )

            VStack(spacing: 8) {
                Text("Hold Fn key to record")
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: hotkeyStatusIcon)
                        .foregroundStyle(hotkeyStatusColor)
                    Text(hotkeyStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if appState.isTranscribing {
                ProgressView("Transcribing...")
                    .padding()
            }

            if let error = appState.lastError {
                VStack(spacing: 8) {
                    Text("Error")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }

            if let transcription = appState.lastTranscription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Transcription:")
                        .font(.headline)
                    Text(transcription)
                        .textSelection(.enabled)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                    Text("Copied to clipboard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .toolbar {
            ToolbarItem {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var hotkeyStatusIcon: String {
        switch appState.hotkeyMonitor.state {
        case .active: return "checkmark.circle.fill"
        case .inactive: return "circle"
        case .permissionDenied: return "exclamationmark.triangle.fill"
        }
    }

    private var hotkeyStatusColor: Color {
        switch appState.hotkeyMonitor.state {
        case .active: return .green
        case .inactive: return .gray
        case .permissionDenied: return .orange
        }
    }

    private var hotkeyStatusText: String {
        switch appState.hotkeyMonitor.state {
        case .active: return "Hotkey monitoring active"
        case .inactive: return "Hotkey monitoring inactive"
        case .permissionDenied: return "Accessibility permission required"
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}

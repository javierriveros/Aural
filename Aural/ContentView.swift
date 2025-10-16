//
//  ContentView.swift
//  Aural
//
//  Created by Javier Riveros on 16/10/25.
//

import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transcription.timestamp, order: .reverse) private var transcriptions: [Transcription]
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 20) {
            RecordingIndicatorView(
                isRecording: appState.audioRecorder.state == .recording,
                isLocked: appState.isRecordingLocked,
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

                if appState.hotkeyMonitor.state == .permissionDenied {
                    VStack(spacing: 8) {
                        Text("Accessibility permission required for global hotkey")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 8) {
                            Button("Request Permission") {
                                appState.hotkeyMonitor.requestPermission()
                            }
                            .controlSize(.small)

                            Button("Open Settings") {
                                openAccessibilitySettings()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)

                            Button("Retry") {
                                _ = appState.hotkeyMonitor.startMonitoring()
                            }
                            .controlSize(.small)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
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

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Transcription History")
                    .font(.headline)

                if transcriptions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No transcriptions yet")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("Hold Fn to start recording")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(transcriptions) { transcription in
                                TranscriptionRow(
                                    transcription: transcription,
                                    onCopy: {
                                        copyToClipboard(transcription.text)
                                    },
                                    onDelete: {
                                        deleteTranscription(transcription)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
        .background(Color(nsColor: .windowBackgroundColor))
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
        .onAppear {
            appState.modelContext = modelContext
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

    private func copyToClipboard(_ text: String) {
        ClipboardService.copy(text)
    }

    private func deleteTranscription(_ transcription: Transcription) {
        modelContext.delete(transcription)
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            print("Failed to create system preferences URL")
            return
        }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}

//
//  ContentView.swift
//  Aural
//
//  Created by Javier Riveros on 16/10/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

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

            Spacer()

            Text("Transcription history will appear here")
                .foregroundStyle(.secondary)
                .font(.callout)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
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

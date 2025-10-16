//
//  ContentView.swift
//  Aural
//
//  Created by Javier Riveros on 16/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var audioRecorder = AudioRecorder()
    @State private var lastRecordingURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            RecordingIndicatorView(
                isRecording: audioRecorder.state == .recording,
                duration: audioRecorder.recordingDuration
            )

            HStack(spacing: 16) {
                Button("Start Recording") {
                    Task {
                        do {
                            let url = try await audioRecorder.startRecording()
                            lastRecordingURL = url
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .disabled(audioRecorder.state == .recording)

                Button("Stop Recording") {
                    lastRecordingURL = audioRecorder.stopRecording()
                }
                .disabled(audioRecorder.state != .recording)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if let url = lastRecordingURL {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Recording:")
                        .font(.headline)
                    Text(url.lastPathComponent)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}

#Preview {
    ContentView()
}

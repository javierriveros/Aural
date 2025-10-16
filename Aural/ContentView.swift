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
    @State private var permissionCheckTimer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            RecordingIndicatorView(
                isRecording: appState.audioRecorder.state == .recording,
                isLocked: appState.isRecordingLocked,
                duration: appState.audioRecorder.recordingDuration
            )

            VStack(spacing: Spacing.xs) {
                HStack(spacing: 6) {
                    Text("Press")
                        .font(Typography.callout)
                        .foregroundStyle(.secondary)
                    Text(appState.hotkeyMonitor.hotkeyConfig.displayString)
                        .font(Typography.monoBody)
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            BrandColors.gradientSecondary
                                .opacity(0.2)
                        )
                        .cornerRadius(CornerRadius.sm)
                    Text("to record")
                        .font(Typography.callout)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(hotkeyStatusColor)
                        .frame(width: 6, height: 6)
                    Text(hotkeyStatusText)
                        .font(Typography.caption)
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
                    .padding(.horizontal, 2)

                if transcriptions.isEmpty {
                    VStack(spacing: Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(BrandColors.gradientSecondary)
                                .frame(width: 100, height: 100)
                                .opacity(0.3)
                                .blur(radius: 30)

                            Circle()
                                .fill(BrandColors.gradientPrimary)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "waveform.badge.mic")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundStyle(.white)
                                )
                        }

                        VStack(spacing: Spacing.xs) {
                            Text("No transcriptions yet")
                                .font(Typography.title2)
                                .foregroundStyle(.primary)

                            Text("Start recording to see your transcriptions here")
                                .font(Typography.callout)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            FeatureHighlight(icon: "mic.fill", title: "Voice Recording", description: "Hold your hotkey to record")
                            FeatureHighlight(icon: "waveform.badge.magnifyingglass", title: "AI Transcription", description: "Powered by Whisper AI")
                            FeatureHighlight(icon: "doc.on.clipboard", title: "Auto Copy", description: "Text copied to clipboard")
                        }
                        .padding(Spacing.md)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        .cornerRadius(CornerRadius.md)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xxl)
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
                        .padding(.horizontal, 2)
                        .padding(.vertical, 8)
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
            startPermissionCheck()
        }
        .onDisappear {
            stopPermissionCheck()
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

    private func startPermissionCheck() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak appState] _ in
            guard let appState = appState else { return }

            if appState.hotkeyMonitor.state == .permissionDenied {
                if appState.hotkeyMonitor.checkAccessibilityPermissionSilently() {
                    _ = appState.hotkeyMonitor.startMonitoring()
                }
            }
        }
    }

    private func stopPermissionCheck() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(BrandColors.primaryBlue)
                .frame(width: 32, height: 32)
                .background(BrandColors.primaryBlue.opacity(0.1))
                .cornerRadius(CornerRadius.sm)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.callout)
                    .fontWeight(.medium)
                Text(description)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}

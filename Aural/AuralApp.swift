import SwiftData
//
//  AuralApp.swift
//  Aural
//
//  Created by Javier Riveros on 16/10/25.
//

import SwiftUI

@main
struct AuralApp: App {
    @State private var appState: AppState = {
        let state = AppState()
        state.modelContext = AuralApp.sharedModelContainer.mainContext
        return state
    }()

    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transcription.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, delete the old database and create a fresh one
            print("Failed to create ModelContainer, attempting to reset database: \(error)")

            // Get the default store URL and delete it
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("shm"))

            // Try creating the container again
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        Window("Aural", id: Self.mainWindowID) {
            ContentView()
                .environment(appState)
                .frame(minWidth: 520, idealWidth: 600,
                       minHeight: 640, idealHeight: 780)
        }
        .modelContainer(Self.sharedModelContainer)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 600, height: 780)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra {
            if let last = appState.lastTranscription {
                Text(last.count > 40 ? last.prefix(40) + "…" : last)
            }
            Button("Copy Last Transcription") {
                if let last = appState.lastTranscription { ClipboardService.copy(last) }
            }
            .disabled(appState.lastTranscription == nil)
            Divider()
            Button("Open Aural") { appState.openMainWindow?() }
            Button("Settings…") {
                appState.showSettings = true
                appState.openMainWindow?()
            }
            Toggle("Launch at Login", isOn: Binding(
                get: { appState.launchAtLogin },
                set: { appState.launchAtLogin = $0 }
            ))
            Divider()
            Button("Quit Aural") { NSApp.terminate(nil) }
        } label: {
            MenuBarIcon(appState: appState)
        }
    }

    static let mainWindowID = "main"
}

// The menu-bar label is the only view guaranteed to exist at launch (the main
// window may be restored closed), so it's where the window opener is captured.
private struct MenuBarIcon: View {
    let appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image(systemName: appState.isTranscribing ? "waveform" : appState.isRecording ? "mic.fill" : "mic")
            .onAppear {
                appState.openMainWindow = {
                    openWindow(id: AuralApp.mainWindowID)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
    }
}

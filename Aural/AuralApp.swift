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
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
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
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 520, idealWidth: 600,
                       minHeight: 640, idealHeight: 780)
        }
        .modelContainer(sharedModelContainer)
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
    }
}

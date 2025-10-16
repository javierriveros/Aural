//
//  AuralApp.swift
//  Aural
//
//  Created by Javier Riveros on 16/10/25.
//

import SwiftUI
import SwiftData

@main
struct AuralApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .modelContainer(for: Transcription.self)
    }
}

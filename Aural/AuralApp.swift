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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 500, idealWidth: 550, maxWidth: 650,
                       minHeight: 400, idealHeight: 600, maxHeight: 800)
        }
        .modelContainer(for: Transcription.self)
        .windowResizability(.contentSize)
        .defaultSize(width: 550, height: 600)
    }
}

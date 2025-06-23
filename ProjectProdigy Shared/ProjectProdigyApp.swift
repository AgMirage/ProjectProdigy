//
//  ProjectProdigyApp.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/23/25.
//


import SwiftUI

@main
struct ProjectProdigyApp: App {
    var body: some Scene {
        WindowGroup {
            // This new GameView replaces the old GameViewController
            GameView()
        }
    }
}

/// This view now manages the top-level state of the app:
/// whether to show character creation or the main tabbed view.
struct GameView: View {
    @State private var player: Player?
    
    // This notification observer will listen for the "Reset Progress"
    // signal from the settings screen.
    private static let resetNotification = NotificationCenter.default.publisher(for: NSNotification.Name("com.projectprodigy.resetProgress"))
    
    var body: some View {
        // When the `player` state variable is nil, show character creation.
        // Otherwise, show the main app view.
        if let activePlayer = player {
            MainView(player: activePlayer)
                .onReceive(GameView.resetNotification) { _ in
                    // When the reset notification is received, set the player to nil
                    // to return to the character creation screen.
                    self.player = nil
                }
        } else {
            CharacterCreationView { newPlayer in
                self.player = newPlayer
            }
        }
    }
}
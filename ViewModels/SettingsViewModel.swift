import Foundation
import SwiftUI

/// Defines the different visual themes available in the app.
enum Theme: String, CaseIterable, Identifiable {
    case classic = "Classic Academia"
    case modern = "Modern Minimalism"
    case cyber = "Cybernetic Study"
    
    var id: Self { self }
}

@MainActor
class SettingsViewModel: ObservableObject {
    
    // --- NEW NOTIFICATION NAME ---
    /// A unique name for the notification that will be sent when the user wants to reset their progress.
    static let resetProgressNotification = Notification.Name("com.projectprodigy.resetProgress")
    
    // MARK: - Published Properties
    
    @Published var selectedTheme: Theme = .classic
    @Published var notificationsEnabled: Bool = true
    @Published var soundEffectsEnabled: Bool = true
    @Published var musicVolume: Double = 0.5
    @Published var isShowingResetAlert: Bool = false
    
    // MARK: - Public Methods
    
    /// This function would apply the theme change across the entire app.
    func applyThemeChange() {
        print("Theme changed to: \(selectedTheme.rawValue)")
        // In a real app, you would post a notification or update a shared app state object.
    }
    
    /// This function now broadcasts a notification to the entire app,
    /// signaling that all progress should be wiped.
    func resetAllProgress() {
        print("--- 'resetAllProgress' called. Posting notification. ---")
        // Post the notification. The GameViewController will be listening for this.
        NotificationCenter.default.post(name: SettingsViewModel.resetProgressNotification, object: nil)
    }
}

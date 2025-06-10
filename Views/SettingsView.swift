import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // --- Section: Appearance ---
                Section(header: Text("Appearance")) {
                    Picker("App Theme", selection: $viewModel.selectedTheme) {
                        ForEach(Theme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .onChange(of: viewModel.selectedTheme) {
                        viewModel.applyThemeChange()
                    }
                }
                
                // --- EDITED SECTION: Added new link ---
                // --- Section: Automation ---
                Section(header: Text("Automation")) {
                    NavigationLink("Automatic Daily Missions") {
                        AutomaticMissionsSettingsView()
                    }
                }
                // --- END EDITED SECTION ---
                
                // --- Section: Sound & Notifications ---
                Section(header: Text("Sound & Notifications")) {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Enable Sound Effects", isOn: $viewModel.soundEffectsEnabled)
                    
                    VStack(alignment: .leading) {
                        Text("Music Volume")
                        Slider(value: $viewModel.musicVolume, in: 0...1)
                    }
                    .padding(.vertical, 5)
                }
                
                // --- Section: Data Management ---
                Section(
                    header: Text("Danger Zone"),
                    footer: Text("Resetting cannot be undone. All of your characters, progress, and items will be permanently deleted.")
                ) {
                    Button("Start Over") {
                        viewModel.isShowingResetAlert = true
                    }
                    .tint(.red)
                }
            }
            .navigationTitle("Settings")
            // Confirmation alert for the reset action
            .alert("Are you absolutely sure?", isPresented: $viewModel.isShowingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset Progress", role: .destructive) {
                    viewModel.resetAllProgress()
                }
            } message: {
                Text("This will delete all of your progress, including stats, knowledge, and items. This action cannot be undone.")
            }
        }
    }
}


// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

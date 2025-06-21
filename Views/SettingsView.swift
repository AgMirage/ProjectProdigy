import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var mainViewModel: MainViewModel // Access the MainViewModel
    @EnvironmentObject var missionsViewModel: MissionsViewModel // --- ADDED: Access the MissionsViewModel

    var body: some View {
        NavigationStack {
            Form {
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
                
                Section(header: Text("Automation")) {
                    // --- EDITED: Pass a binding to the settings from the MissionsViewModel ---
                    NavigationLink("Automatic Daily Missions") {
                        AutomaticMissionsSettingsView(settings: $missionsViewModel.dailyMissionSettings)
                    }
                }
                
                Section(header: Text("Sound & Notifications")) {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Enable Sound Effects", isOn: $viewModel.soundEffectsEnabled)
                    
                    VStack(alignment: .leading) {
                        Text("Music Volume")
                        Slider(value: $viewModel.musicVolume, in: 0...1)
                    }
                    .padding(.vertical, 5)
                }
                
                // --- NEW: Data Management Section ---
                Section(header: Text("Data Management")) {
                    NavigationLink("View Mission Archive") {
                        // Pass the archived missions from the MainViewModel
                        ArchiveView(archivedMissions: mainViewModel.archivedMissions)
                    }
                }
                
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
        let mainVM = MainViewModel(player: Player(username: "Preview"))
        // The preview now needs the MainViewModel in its environment
        SettingsView()
            .environmentObject(mainVM)
            // --- ADDED: Also provide the MissionsViewModel for the preview ---
            .environmentObject(MissionsViewModel(mainViewModel: mainVM))
    }
}

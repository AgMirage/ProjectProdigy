import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var missionsViewModel: MissionsViewModel

    @State private var isShowingTimerSettings = false

    var body: some View {
        #if os(macOS)
        settingsContent
        #else
        NavigationStack {
            settingsContent
        }
        #endif
    }
    
    private var settingsContent: some View {
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
                
                NavigationLink(destination: AvatarGalleryView()) {
                    Label("Avatar Gallery", systemImage: "person.crop.rectangle.stack")
                }
            }
            
            Section(header: Text("Automation & Timers")) {
                Button("Mission & Timer Settings") {
                    isShowingTimerSettings = true
                }
            }
            
            Section(header: Text("Sound & Notifications")) {
                // --- THIS IS THE NEWLY ADDED TOGGLE ---
                Toggle("Mute Videos", isOn: $mainViewModel.player.areVideosMuted)
                // -----------------------------------------
                
                Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                Toggle("Enable Sound Effects", isOn: $viewModel.soundEffectsEnabled)
                
                VStack(alignment: .leading) {
                    Text("Music Volume")
                    Slider(value: $viewModel.musicVolume, in: 0...1)
                }
                .padding(.vertical, 5)
            }
            
            Section(header: Text("Data Management")) {
                NavigationLink("View Mission Archive") {
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
        .sheet(isPresented: $isShowingTimerSettings) {
            TimerSettingsView(settings: $missionsViewModel.dailyMissionSettings)
        }
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

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let mainVM = MainViewModel(player: Player(username: "Preview"))
        SettingsView()
            .environmentObject(mainVM)
            .environmentObject(MissionsViewModel(mainViewModel: mainVM))
    }
}

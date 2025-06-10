//
//  TitlesView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import SwiftUI

struct TitlesView: View {
    
    // This view gets the single source of truth from the environment.
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // The dismiss action allows us to close the sheet.
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(mainViewModel.player.unlockedTitles) { title in
                Button(action: {
                    // When a title is tapped, update the player's active title.
                    mainViewModel.player.activeTitle = title
                    // Close the sheet after selection.
                    dismiss()
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(title.name)
                                .font(.headline)
                            Text(title.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Show a checkmark next to the currently active title.
                        if mainViewModel.player.activeTitle?.id == title.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                                .font(.headline.bold())
                        }
                    }
                    .foregroundColor(.primary) // Ensure button text is the default color
                }
            }
            .navigationTitle("Select a Title")
            // --- FIXED: This modifier is unavailable on macOS, so we wrap it for iOS only. ---
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                // --- FIXED: Changed placement to '.primaryAction' for macOS compatibility. ---
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


// MARK: - Preview
struct TitlesView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy player and viewModel for the preview.
        let player = Player(username: "Preview")
        let mainVM = MainViewModel(player: player)
        
        // Manually add some titles for the preview to work.
        mainVM.player.unlockedTitles = [
            TitleList.byId("emergent_expert")!,
            TitleList.byId("weekly_warrior")!
        ]
        mainVM.player.activeTitle = TitleList.byId("emergent_expert")!
        
        return TitlesView()
            .environmentObject(mainVM)
    }
}

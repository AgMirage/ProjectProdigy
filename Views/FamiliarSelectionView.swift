//
//  FamiliarSelectionView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/30/25.
//


import SwiftUI

/// A view that allows the player to swap their active familiar.
struct FamiliarSelectionView: View {

    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(mainViewModel.player.unlockedFamiliars, id: \.id) { familiar in
                Button(action: {
                    mainViewModel.player.activeFamiliar = familiar
                    dismiss()
                }) {
                    HStack(spacing: 15) {
                        Image(familiar.imageNamePrefix + "_stage_1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text(familiar.name).font(.headline)
                            Text("Level \(familiar.level)").font(.caption)
                        }
                        
                        Spacer()
                        
                        if mainViewModel.player.activeFamiliar.id == familiar.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Familiar")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}


struct FamiliarSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "Preview")
        let mainVM = MainViewModel(player: player)
        
        FamiliarSelectionView()
            .environmentObject(mainVM)
    }
}
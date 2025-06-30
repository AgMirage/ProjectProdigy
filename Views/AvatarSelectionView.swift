//
//  AvatarSelectionView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/30/25.
//


import SwiftUI

/// A view that allows the player to select from their unlocked avatars.
struct AvatarSelectionView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    @Environment(\.dismiss) var dismiss
    
    // Define grid layout
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(mainViewModel.player.unlockedAvatars, id: \.imageName) { avatar in
                        VStack {
                            Image(avatar.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .padding(4)
                                .overlay(
                                    Circle().stroke(Color.blue, lineWidth: mainViewModel.player.currentAvatar.imageName == avatar.imageName ? 4 : 0)
                                )
                                .onTapGesture {
                                    // Set the new avatar and close the sheet
                                    mainViewModel.player.currentAvatar = avatar
                                    dismiss()
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Avatar")
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

struct AvatarSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "Preview")
        let mainVM = MainViewModel(player: player)
        
        AvatarSelectionView()
            .environmentObject(mainVM)
    }
}
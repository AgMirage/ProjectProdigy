//
//  AvatarGalleryView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 8/15/25.
//


import SwiftUI

struct AvatarGalleryView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // Define grid layout
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(AvatarList.allAvatars) { avatarData in
                        let isUnlocked = mainViewModel.player.unlockedAvatars.contains { $0.imageName == avatarData.id }
                        
                        VStack {
                            Image(avatarData.id)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .saturation(isUnlocked ? 1.0 : 0.0) // Grayscale if not unlocked
                                .overlay(
                                    Circle().stroke(isUnlocked ? Color.blue : Color.gray, lineWidth: 2)
                                )
                            
                            Text(avatarData.name)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                            
                            if !isUnlocked {
                                Text(avatarData.unlockMethod)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Avatar Gallery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

struct AvatarGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "Preview")
        let mainVM = MainViewModel(player: player)
        
        // Manually unlock some avatars for the preview
        mainVM.player.unlockedAvatars.append(Avatar(imageName: "Avatar_feminine_summer_scholar_1", description: "Summer Scholar"))
        
        return AvatarGalleryView()
            .environmentObject(mainVM)
    }
}
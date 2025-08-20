import SwiftUI

struct WallpaperView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        ZStack {
            if let wallpaper = mainViewModel.player.activeWallpaper {
                // Pass the mute setting from the player object
                VideoPlayerView(
                    videoName: wallpaper,
                    isMuted: mainViewModel.player.areVideosMuted
                )
                .ignoresSafeArea()
            } else {
                // Default background
                Color.black.ignoresSafeArea()
            }
            
            // Your other UI elements go here
        }
    }
}

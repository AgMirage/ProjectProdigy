import SwiftUI

struct WallpaperView: View {
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        ZStack {
            if let wallpaper = mainViewModel.player.activeWallpaper {
                VideoPlayerView(videoName: wallpaper)
                    .ignoresSafeArea() // Correct way to make the view ignore safe areas
            } else {
                // Default background should also ignore the safe area
                Color.black
                    .ignoresSafeArea()
            }
            
            // Your other UI elements will go on top of the video background
        }
    }
}

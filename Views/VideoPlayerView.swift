import SwiftUI
import AVKit

#if os(iOS) // Code for iOS (No changes here, this part was correct)
import UIKit

// A custom UIView subclass that is backed by an AVPlayerLayer
class PlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    var videoGravity: AVLayerVideoGravity {
        get { return playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
}

// The UIViewRepresentable that bridges our custom UIView into SwiftUI for iOS
struct VideoPlayerView: UIViewRepresentable {
    var videoName: String

    func makeUIView(context: Context) -> UIView {
        let playerUIView = PlayerUIView(frame: .zero)
        
        guard let asset = NSDataAsset(name: videoName) else {
            print("Video asset '\(videoName)' not found.")
            return playerUIView
        }
        
        let tempURL = createTemporaryURL(for: asset.data)
        
        if let url = tempURL {
            let player = AVPlayer(url: url)
            playerUIView.player = player
            playerUIView.videoGravity = .resizeAspectFill
            
            context.coordinator.player = player
            context.coordinator.tempURL = url
            
            player.play()
        }
        
        return playerUIView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var player: AVPlayer?
        var tempURL: URL?

        init(_ parent: VideoPlayerView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
            if let url = tempURL {
                try? FileManager.default.removeItem(at: url)
            }
        }

        @objc func playerItemDidReachEnd(notification: Notification) {
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

#elseif os(macOS) // ---- START OF CORRECTED MACOS CODE ----
import AppKit

// A custom NSView subclass that is backed by an AVPlayerLayer
class PlayerNSView: NSView {
    private var playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        // Explicitly set this view to be layer-backed
        wantsLayer = true
        // Set our custom playerLayer as the view's main layer
        layer = playerLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }

    var videoGravity: AVLayerVideoGravity {
        get { return playerLayer.videoGravity }
        set { playerLayer.videoGravity = newValue }
    }
    
    // The layout method is important on macOS to resize the layer with the view
    override func layout() {
        super.layout()
        playerLayer.frame = self.bounds
    }
}


// The NSViewRepresentable that bridges our custom NSView into SwiftUI for macOS
struct VideoPlayerView: NSViewRepresentable {
    var videoName: String

    func makeNSView(context: Context) -> NSView {
        let playerNSView = PlayerNSView(frame: .zero)
        
        guard let asset = NSDataAsset(name: videoName) else {
            print("Video asset '\(videoName)' not found.")
            return playerNSView
        }
        
        let tempURL = createTemporaryURL(for: asset.data)
        
        if let url = tempURL {
            let player = AVPlayer(url: url)
            playerNSView.player = player
            playerNSView.videoGravity = .resizeAspectFill
            
            context.coordinator.player = player
            context.coordinator.tempURL = url
            
            player.play()
        }
        
        return playerNSView
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var player: AVPlayer?
        var tempURL: URL?

        init(_ parent: VideoPlayerView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
            if let url = tempURL {
                try? FileManager.default.removeItem(at: url)
            }
        }

        @objc func playerItemDidReachEnd(notification: Notification) {
            player?.seek(to: .zero)
            player?.play()
        }
    }
}
#endif // ---- END OF CORRECTED MACOS CODE ----

// Helper function available to both platforms
fileprivate func createTemporaryURL(for data: Data) -> URL? {
    let fileManager = FileManager.default
    let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let tempURL = cacheDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
    
    do {
        try data.write(to: tempURL)
        return tempURL
    } catch {
        print("Error writing temporary video file: \(error)")
        return nil
    }
}

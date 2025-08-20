import SwiftUI
import AVKit

#if os(iOS) // Code for iOS
import UIKit

class PlayerUIView: UIView {
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    // Set the background color to clear when the view is created
    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.backgroundColor = UIColor.clear.cgColor
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
}

struct VideoPlayerView: UIViewRepresentable {
    var videoName: String
    var isMuted: Bool

    func makeUIView(context: Context) -> UIView {
        let playerUIView = PlayerUIView(frame: .zero)
        
        guard let asset = NSDataAsset(name: videoName) else {
            print("Video asset '\(videoName)' not found.")
            return playerUIView
        }
        
        let tempURL = createTemporaryURL(for: asset.data)
        
        if let url = tempURL {
            let player = AVPlayer(url: url)
            player.isMuted = isMuted
            playerUIView.player = player
            playerUIView.videoGravity = .resizeAspectFill
            
            context.coordinator.player = player
            context.coordinator.tempURL = url
            
            player.play()
        }
        
        return playerUIView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let playerView = uiView as? PlayerUIView {
            playerView.player?.isMuted = isMuted
        }
    }

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

#elseif os(macOS) // Code for macOS
import AppKit

class PlayerNSView: NSView {
    private var playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        // Set the background color to clear
        playerLayer.backgroundColor = NSColor.clear.cgColor
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
    
    override func layout() {
        super.layout()
        playerLayer.frame = self.bounds
    }
}

struct VideoPlayerView: NSViewRepresentable {
    var videoName: String
    var isMuted: Bool

    func makeNSView(context: Context) -> NSView {
        let playerNSView = PlayerNSView(frame: .zero)
        
        guard let asset = NSDataAsset(name: videoName) else {
            print("Video asset '\(videoName)' not found.")
            return playerNSView
        }
        
        let tempURL = createTemporaryURL(for: asset.data)
        
        if let url = tempURL {
            let player = AVPlayer(url: url)
            player.isMuted = isMuted
            playerNSView.player = player
            playerNSView.videoGravity = .resizeAspectFill
            
            context.coordinator.player = player
            context.coordinator.tempURL = url
            
            player.play()
        }
        
        return playerNSView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let playerView = nsView as? PlayerNSView {
            playerView.player?.isMuted = isMuted
        }
    }

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
#endif

// Helper function
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

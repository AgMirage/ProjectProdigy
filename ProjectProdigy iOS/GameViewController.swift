// This file is now correctly cross-platform.

#if canImport(UIKit)
import UIKit
typealias PlatformViewController = UIViewController
#elseif canImport(AppKit)
import AppKit
typealias PlatformViewController = NSViewController
#endif

import SpriteKit
import SwiftUI

class GameViewController: PlatformViewController {
    
    private var player: Player?
    private var currentChildVC: PlatformViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- ADDED NOTIFICATION OBSERVER ---
        // The controller now listens for the 'reset' message from the Settings screen.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResetProgress),
            name: SettingsViewModel.resetProgressNotification,
            object: nil
        )
        // --- END ADDED ---
        
        self.presentInitialView()
    }
    
    /// This function is called when the reset notification is received.
    @objc private func handleResetProgress() {
        print("Reset notification received! Wiping player data and returning to character creation.")
        self.player = nil
        self.presentInitialView()
    }
    
    /// This function decides which view to show: Character Creation or the Main Dashboard.
    private func presentInitialView() {
        if let activePlayer = self.player {
            let mainView = MainView(player: activePlayer)
            display(swiftUIView: mainView)
        } else {
            let creationView = CharacterCreationView { [weak self] newPlayer in
                self?.player = newPlayer
                self?.presentInitialView()
            }
            display(swiftUIView: creationView)
        }
    }
    
    /// A helper function to properly add and remove child view controllers.
    private func display<V: View>(swiftUIView: V) {
        if let existingVC = currentChildVC {
            #if canImport(UIKit)
            existingVC.willMove(toParent: nil)
            #endif
            existingVC.view.removeFromSuperview()
            existingVC.removeFromParent()
        }
        
        #if canImport(UIKit)
        let hostingController = UIHostingController(rootView: swiftUIView)
        #elseif canImport(AppKit)
        let hostingController = NSHostingController(rootView: swiftUIView)
        #endif
        
        self.addChild(hostingController)
        self.view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
        
        #if canImport(UIKit)
        hostingController.didMove(toParent: self)
        #endif
        
        self.currentChildVC = hostingController
    }

    // This code will only be included when compiling for iOS/UIKit targets.
    #if canImport(UIKit)
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    #endif
}

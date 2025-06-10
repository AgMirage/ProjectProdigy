import Foundation
import SwiftUI

@MainActor
class FountainViewModel: ObservableObject {
    
    @Published var lastReward: GachaReward?
    @Published var isPulling: Bool = false
    @Published var alertItem: AlertItem?
    
    let pullCost: Int = 100
    private let rewardPool: [GachaReward]
    
    weak var mainViewModel: MainViewModel?
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.rewardPool = GachaPool.allRewards
    }
    
    /// The main function to perform a gacha pull.
    func pullFromFountain() {
        guard let mainVM = mainViewModel, mainVM.player.gold >= pullCost else {
            alertItem = AlertItem(title: "Not Enough Gold", message: "You need \(pullCost) Gold to make a wish at the Fountain.")
            return
        }
        
        isPulling = true
        lastReward = nil
        mainVM.player.gold -= pullCost
        
        let winningReward = performWeightedRoll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.grantReward(winningReward)
            self.lastReward = winningReward
            self.isPulling = false
        }
    }
    
    private func performWeightedRoll() -> GachaReward {
        let totalRarityWeight = GachaRarity.allCases.reduce(0) { $0 + $1.probabilityWeight }
        let randomRoll = Int.random(in: 1...totalRarityWeight)
        
        var cumulativeWeight = 0
        var winningRarity: GachaRarity = .common
        
        for rarity in GachaRarity.allCases.sorted(by: { $0.probabilityWeight > $1.probabilityWeight }) {
            cumulativeWeight += rarity.probabilityWeight
            if randomRoll <= cumulativeWeight {
                winningRarity = rarity
                break
            }
        }
        
        let itemsInWinningRarity = rewardPool.filter { $0.rarity == winningRarity }
        return itemsInWinningRarity.randomElement() ?? GachaPool.allRewards.first(where: { $0.rarity == .common })!
    }
    
    /// Adds the won item to the player's appropriate inventory list.
    private func grantReward(_ reward: GachaReward) {
        guard var player = mainViewModel?.player else { return }
        
        switch reward.type {
        // --- UPDATED LOGIC ---
        case .avatar:
            var frame: String? = nil
            // Special case: If this specific avatar is won, grant its frame too.
            if reward.assetName == "avatar_legendary_scholar" {
                frame = "frame_celestial_animated"
            }
            let newAvatar = Avatar(imageName: reward.assetName, frameName: frame, description: reward.name, price: nil)
            player.unlockedAvatars.append(newAvatar)
            
        // The .avatarFrame case has been removed.
        
        case .theme:
            player.unlockedThemes.append(reward.assetName)

        case .familiarSkin:
            guard let familiarName = reward.targetFamiliarName else { return }
            if player.unlockedFamiliarSkins[familiarName] != nil {
                player.unlockedFamiliarSkins[familiarName]?.append(reward.assetName)
            } else {
                player.unlockedFamiliarSkins[familiarName] = [reward.assetName]
            }
            
        case .gold:
            player.gold += reward.goldAmount ?? 0
        // --- END UPDATED LOGIC ---
        }
        
        mainViewModel?.player = player
        print("Granted Reward: \(reward.name)")
    }
}

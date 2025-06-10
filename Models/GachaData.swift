import Foundation
import SwiftUI

/// The different categories of rewards available from the Fountain.
enum GachaRewardType: String, Codable {
    // .avatarFrame has been removed.
    case avatar, theme, familiarSkin, gold
}

/// The rarity level of a gacha reward, which determines its color and drop chance.
enum GachaRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var probabilityWeight: Int {
        switch self {
        case .common: return 100
        case .uncommon: return 50
        case .rare: return 20
        case .epic: return 5
        case .legendary: return 1
        }
    }
}

/// A blueprint for a single item that can be won from the Fountain of Knowledge.
struct GachaReward: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let type: GachaRewardType
    let rarity: GachaRarity
    let assetName: String
    let targetFamiliarName: String?
    let goldAmount: Int?
    
    init(id: UUID = UUID(), name: String, type: GachaRewardType, rarity: GachaRarity, assetName: String, targetFamiliarName: String? = nil, goldAmount: Int? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.rarity = rarity
        self.assetName = assetName
        self.targetFamiliarName = targetFamiliarName
        self.goldAmount = goldAmount
    }
}


/// A static "factory" that defines the entire prize pool for the Gacha system.
struct GachaPool {
    static let allRewards: [GachaReward] = [
        // --- COMMON ---
        GachaReward(name: "10 Gold", type: .gold, rarity: .common, assetName: "gold_10", goldAmount: 10),
        GachaReward(name: "25 Gold", type: .gold, rarity: .common, assetName: "gold_25", goldAmount: 25),
        
        // --- UNCOMMON ---
        GachaReward(name: "50 Gold", type: .gold, rarity: .uncommon, assetName: "gold_50", goldAmount: 50),
        GachaReward(name: "Scholar Avatar", type: .avatar, rarity: .uncommon, assetName: "avatar_scholar_gacha"),
        
        // --- RARE ---
        GachaReward(name: "100 Gold", type: .gold, rarity: .rare, assetName: "gold_100", goldAmount: 100),
        GachaReward(name: "Minimalist Theme", type: .theme, rarity: .rare, assetName: "theme_minimalist"),
        GachaReward(name: "Steampunk Gnomon Skin", type: .familiarSkin, rarity: .rare, assetName: "skin_gnomon_steampunk", targetFamiliarName: "Gnomon"),
        
        // --- EPIC ---
        GachaReward(name: "Cybernetic Theme", type: .theme, rarity: .epic, assetName: "theme_cybernetic"),
        GachaReward(name: "Floral Sprout Skin", type: .familiarSkin, rarity: .epic, assetName: "skin_sprout_floral", targetFamiliarName: "Sprout"),
        
        // --- LEGENDARY ---
        // This avatar now implicitly comes with the "Celestial Frame". We'll handle this in the ViewModel.
        GachaReward(name: "Legendary Scholar Avatar", type: .avatar, rarity: .legendary, assetName: "avatar_legendary_scholar"),
        GachaReward(name: "Magma Codex Skin", type: .familiarSkin, rarity: .legendary, assetName: "skin_codex_magma", targetFamiliarName: "Codex")
    ]
}

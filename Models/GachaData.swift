import Foundation
import SwiftUI

/// The different categories of rewards available from the Fountain.
enum GachaRewardType: String, Codable {
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
        GachaReward(name: "Cybernetic Scholar Tablet Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_feminine_cyberscholar_tablet_lightskin"),
        GachaReward(name: "Elegant Energy Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_feminine_elegant_energy_lightskin"),
        GachaReward(name: "Styled Hair Energy Eyes Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_styledhair_energyeyes_darkskin"),
        GachaReward(name: "Bow Hologram Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_bow_hologram_darkskin"),
        GachaReward(name: "Techmage Cube Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_feminine_techmage_cube_lightskin"),
        GachaReward(name: "Scientist Cube Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_feminine_scientist_cube_lightskin"),
        GachaReward(name: "Tech Scholar Cube Darkskin Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_techscholar_cube_darkskin"),
        GachaReward(name: "Tech Scholar Cube Lightskin Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_techscholar_cube_lightskin"),
        GachaReward(name: "Tech Genius Cube Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_techgenius_cube_lightskin"),
        GachaReward(name: "Orange Energy Mage Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_energymage_orange_darkskin"),
        GachaReward(name: "Blue Energy Mage Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_energymage_blue_darkskin"),
        GachaReward(name: "Pyromancer Fireglow Avatar", type: .avatar, rarity: .rare, assetName: "Avatar_masculine_pyromancer_fireglow_lightskin"),
        GachaReward(name: "Scholarly Owl Avatar", type: .avatar, rarity: .rare, assetName: "avatar_owl_scholarly_cuteglow_woodframe"),
        
        // --- EPIC ---
        GachaReward(name: "Cybernetic Theme", type: .theme, rarity: .epic, assetName: "theme_cybernetic"),
        GachaReward(name: "Floral Sprout Skin", type: .familiarSkin, rarity: .epic, assetName: "skin_sprout_floral", targetFamiliarName: "Sprout"),
        GachaReward(name: "Golden Eyes Techsplit Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_feminine_goldeneyes_techsplit_darkskin"),
        GachaReward(name: "Suit Energy Eyes Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_masculine_suit_energyeyes_bluelight_lightskin"),
        GachaReward(name: "Curly Hair Cosmic Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_feminine_curlyhair_cosmic_darkskin"),
        GachaReward(name: "Cosmic Scholar Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_masculine_cosmic_scholar_lightskin_formal"),
        GachaReward(name: "Sleek Cosmic Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_masculine_sleek_cosmic_lightskin_formal"),
        GachaReward(name: "Cosmic Stargazer Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_feminine_cosmic_stargazer_lightskin"),
        GachaReward(name: "Duality Split Energy Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_masculine_duality_splitenergy_lightskin"),
        GachaReward(name: "Kinetic Power Avatar", type: .avatar, rarity: .epic, assetName: "Avatar_feminine_kinetic_power_darkskin"),
        
        // --- LEGENDARY ---
        GachaReward(name: "Legendary Scholar Avatar", type: .avatar, rarity: .legendary, assetName: "avatar_legendary_scholar"),
        GachaReward(name: "Magma Codex Skin", type: .familiarSkin, rarity: .legendary, assetName: "skin_codex_magma", targetFamiliarName: "Codex"),
        GachaReward(name: "Cosmic Suit Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_masculine_cosmic_suit_darkskin"),
        GachaReward(name: "Cosmic Knight Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_masculine_cosmic_knight_lightskin"),
        GachaReward(name: "Ethereal Cosmic Duality Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_ethereal_cosmic_duality_glowing"),
        GachaReward(name: "Cosmic Contemplation Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_feminine_cosmic_contemplation_lightskin"),
        GachaReward(name: "Goddess Knowledge Orb Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_feminine_goddess_knowledgeorb_goldglow"),
        GachaReward(name: "Celestial Knowledge Orb Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_feminine_celestial_knowledgeorb_goldglow"),
        GachaReward(name: "Celestial Dragon Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_dragon_celestial_iridescent_goldframe"),
        GachaReward(name: "Cosmic Dragon Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_dragon_cosmic_dynamic_goldframe"),
        GachaReward(name: "Elemental Duality Dragon Avatar", type: .avatar, rarity: .legendary, assetName: "Avatar_dragon_elemental_duality_crackedframe")
    ]
}

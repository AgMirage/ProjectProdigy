//
//  AvatarData.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 8/15/25.
//


import Foundation

/// Represents a single avatar, including how to unlock it.
struct AvatarData: Identifiable {
    let id: String
    let name: String
    let unlockMethod: String
    
    init(imageName: String, unlockMethod: String) {
        self.id = imageName
        self.name = imageName.replacingOccurrences(of: "_", with: " ").capitalized
        self.unlockMethod = unlockMethod
    }
}

/// A static data source for all avatars available in the game.
struct AvatarList {
    static let allAvatars: [AvatarData] = [
        // Default Avatars
        AvatarData(imageName: "avatar_f_generic_01", unlockMethod: "Default"),
        AvatarData(imageName: "avatar_f_generic_02", unlockMethod: "Default"),
        AvatarData(imageName: "avatar_m_generic_01", unlockMethod: "Default"),
        AvatarData(imageName: "avatar_m_generic_02", unlockMethod: "Default"),
        
        // Achievement Unlocks
        AvatarData(imageName: "Avatar_feminine_summer_scholar_1", unlockMethod: "Complete the 'Summer of Study' event."),
        AvatarData(imageName: "Avatar_feminine_summer_scholar_2", unlockMethod: "Complete the 'Summer of Study' event."),
        AvatarData(imageName: "Avatar_masculine_summer_scholar_1", unlockMethod: "Complete the 'Summer of Study' event."),
        AvatarData(imageName: "Avatar_masculine_summer_scholar_2", unlockMethod: "Complete the 'Summer of Study' event."),
        AvatarData(imageName: "Avatar_masculine_inventor_book_techglow_darkskin", unlockMethod: "Complete 'The Alchemist's Manuscript' story."),
        AvatarData(imageName: "Avatar_feminine_cosmic_sorceress_paleglow", unlockMethod: "Complete 'The Alchemist's Manuscript' story."),
        AvatarData(imageName: "Avatar_feminine_tech_scarf_cyberglow_mediumskin", unlockMethod: "Complete 'The Silicon Soul' story."),
        AvatarData(imageName: "Avatar_masculine_tech_glowingeyes_darkskin", unlockMethod: "Complete 'The Silicon Soul' story."),
        
        // Store Purchases
        AvatarData(imageName: "Avatar_feminine_academic_scroll_warmglow_lightskin", unlockMethod: "Purchase from the store for 1,500 Gold."),
        AvatarData(imageName: "Avatar_feminine_formal_book_bluelight_lightskin", unlockMethod: "Purchase from the store for 1,500 Gold."),
        AvatarData(imageName: "Avatar_masculine_classic_scholar_owl_lightskin", unlockMethod: "Purchase from the store for 2,000 Gold."),
        AvatarData(imageName: "Avatar_feminine_glasses_scholar_darkskin_globe", unlockMethod: "Purchase from the store for 2,000 Gold."),
        AvatarData(imageName: "Avatar_masculine_glasses_formal_darkskin_library", unlockMethod: "Purchase from the store for 2,000 Gold."),
        
        // Gacha Avatars
        AvatarData(imageName: "Avatar_feminine_cyberscholar_tablet_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_elegant_energy_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_styledhair_energyeyes_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_bow_hologram_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_techmage_cube_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_scientist_cube_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_techscholar_cube_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_techscholar_cube_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_techgenius_cube_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_energymage_orange_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_energymage_blue_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_pyromancer_fireglow_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "avatar_owl_scholarly_cuteglow_woodframe", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_goldeneyes_techsplit_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_suit_energyeyes_bluelight_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_curlyhair_cosmic_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_cosmic_scholar_lightskin_formal", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_sleek_cosmic_lightskin_formal", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_cosmic_stargazer_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_duality_splitenergy_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_kinetic_power_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_cosmic_suit_darkskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_masculine_cosmic_knight_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_ethereal_cosmic_duality_glowing", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_cosmic_contemplation_lightskin", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_goddess_knowledgeorb_goldglow", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_feminine_celestial_knowledgeorb_goldglow", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_dragon_celestial_iridescent_goldframe", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_dragon_cosmic_dynamic_goldframe", unlockMethod: "Found in the Fountain of Knowledge."),
        AvatarData(imageName: "Avatar_dragon_elemental_duality_crackedframe", unlockMethod: "Found in the Fountain of Knowledge.")
    ]
}
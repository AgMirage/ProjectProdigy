import Foundation
import SwiftUI

/// Defines the rarity and visual style of an achievement.
enum AchievementTier: String, Codable, CaseIterable {
    case Bronze, Silver, Gold, Onyx, Sapphire, Diamond
    
    var imageName: String {
        switch self {
        case .Bronze: return "tier_bronze"
        case .Silver: return "tier_silver"
        case .Gold: return "tier_gold"
        case .Onyx: return "tier_onyx"
        case .Sapphire: return "tier_sapphire"
        case .Diamond: return "tier_diamond"
        }
    }
    
    var color: Color {
        switch self {
        case .Bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .Silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .Gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .Onyx: return Color(red: 0.2, green: 0.2, blue: 0.2)
        case .Sapphire: return Color(red: 0.05, green: 0.3, blue: 0.5)
        case .Diamond: return Color.cyan
        }
    }
}

/// The static definition of a single achievement blueprint.
struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let tier: AchievementTier
    let goldReward: Int
    let goal: Double
    let isSecret: Bool
    
    // --- NEW PROPERTY ---
    /// The ID of a Title to be awarded upon completion, if any.
    let titleRewardID: String?
    
    init(id: String, name: String, description: String, tier: AchievementTier, goldReward: Int, goal: Double, isSecret: Bool, titleRewardID: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.tier = tier
        self.goldReward = goldReward
        self.goal = goal
        self.isSecret = isSecret
        self.titleRewardID = titleRewardID
    }
}

/// Tracks an individual player's progress towards a specific achievement.
struct PlayerAchievementStatus: Identifiable, Codable, Hashable {
    let id: String
    var progress: Double
    var isUnlocked: Bool
    var unlockedDate: Date?
}

/// A static "factory" that defines all achievements available in the game.
struct AchievementList {
    
    static let allAchievements: [Achievement] = [
        // --- BRONZE TIER ---
        Achievement(id: "first_mission", name: "First Step", description: "Complete your first mission.", tier: .Bronze, goldReward: 50, goal: 1, isSecret: false),
        Achievement(id: "streak_3_days", name: "Getting Consistent", description: "Reach a 3-day check-in streak.", tier: .Bronze, goldReward: 75, goal: 3, isSecret: false),
        Achievement(id: "earn_1000_gold", name: "Apprentice Saver", description: "Earn a total of 1,000 Gold.", tier: .Bronze, goldReward: 100, goal: 1000, isSecret: false),

        // --- SILVER TIER ---
        Achievement(id: "missions_completed_50", name: "Diligent Student", description: "Complete a total of 50 missions.", tier: .Silver, goldReward: 250, goal: 50, isSecret: false),
        // This achievement now rewards a title.
        Achievement(id: "streak_7_days", name: "Weekly Warrior", description: "Reach a 7-day check-in streak.", tier: .Silver, goldReward: 300, goal: 7, isSecret: false, titleRewardID: "weekly_warrior"),
        
        // --- GOLD TIER ---
        // This achievement now rewards a title.
        Achievement(id: "reach_level_10", name: "Emergent Expert", description: "Reach Character Level 10 (Emergent Expert).", tier: .Gold, goldReward: 1000, goal: 10, isSecret: false, titleRewardID: "emergent_expert"),
        Achievement(id: "master_college_branch", name: "Major Milestone", description: "Fully complete all topics in a college-level main branch.", tier: .Gold, goldReward: 1500, goal: 1, isSecret: false),
        
        // --- ONYX TIER ---
        Achievement(id: "missions_completed_500", name: "Dedicated Scholar", description: "Complete a total of 500 missions.", tier: .Onyx, goldReward: 5000, goal: 500, isSecret: false),

        // --- SECRET ACHIEVEMENT ---
        Achievement(id: "early_bird", name: "The Early Bird", description: "Complete a mission before 8:00 AM.", tier: .Silver, goldReward: 200, goal: 1, isSecret: true)
    ]
    
    /// A helper function to easily find an achievement by its ID.
    static func byId(_ id: String) -> Achievement? {
        return allAchievements.first { $0.id == id }
    }
}

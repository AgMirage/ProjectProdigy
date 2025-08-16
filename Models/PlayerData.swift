import Foundation
import SwiftUI

// MARK: - Mastery Level
/// Represents the mastery goal set by the player for a specific branch.
enum MasteryLevel: String, Codable, CaseIterable, Comparable {
    case standard = "Standard"
    case proficient = "Proficient"
    case mastery = "Mastery"
    
    /// The multiplier applied to the baseline requirements for this level.
    var multiplier: Double {
        switch self {
        case .standard: return 1.0
        case .proficient: return 1.25
        case .mastery: return 1.50
        }
    }
    
    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        let allLevels = MasteryLevel.allCases
        guard let lhsIndex = allLevels.firstIndex(of: lhs),
              let rhsIndex = allLevels.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}


/// Stores the player-specific mastery choice for a single knowledge branch.
struct PlayerBranchMastery: Codable, Hashable {
    let branchID: String
    var level: MasteryLevel
}


// MARK: - Avatar
struct Avatar: Codable, Hashable {
    var imageName: String
    var frameName: String?
    var description: String
    var price: Int?
}

// MARK: - Familiar
struct Familiar: Codable, Hashable {
    let id: UUID
    var name: String
    var imageNamePrefix: String
    var level: Int
    var xp: Double
    
    init(id: UUID = UUID(), name: String, imageNamePrefix: String, level: Int = 1, xp: Double = 0.0) {
        self.id = id
        self.name = name
        self.imageNamePrefix = imageNamePrefix
        self.level = level
        self.xp = xp
    }
}

// MARK: - Academic Tier
enum AcademicTier: String, CaseIterable, Codable {
    case foundationalApprentice = "Foundational Apprentice", skilledScholar = "Skilled Scholar", emergentExpert = "Emergent Expert", masterPolymath = "Master Polymath", pinnacleProdigy = "Pinnacle Prodigy"
    var level: Int {
        switch self {
        case .foundationalApprentice: return 1; case .skilledScholar: return 6; case .emergentExpert: return 11; case .masterPolymath: return 16; case .pinnacleProdigy: return 21
        }
    }
}


// MARK: - Core Stats
struct Stats: Codable {
    var intelligence: Int, wisdom: Int, dexterity: Int, creativity: Int, stamina: Int, focus: Int
    static var `default`: Stats { Stats(intelligence: 5, wisdom: 5, dexterity: 5, creativity: 5, stamina: 5, focus: 5) }
}


// MARK: - Player
struct Player: Codable {
    let id: UUID
    var username: String
    
    // Cosmetics
    var currentAvatar: Avatar
    var unlockedAvatars: [Avatar]
    var unlockedTitles: [Title]
    var activeTitle: Title?
    var unlockedFamiliars: [Familiar]
    var activeFamiliar: Familiar
    var unlockedThemes: [String]
    var unlockedFamiliarSkins: [String: [String]]

    // State & Progression
    var procrastinationMonsterValue: Double = 0.0
    var academicTier: AcademicTier
    var stats: Stats
    var totalXP: Double
    var gold: Int
    var checkInStreak: Int
    var lastMissionCompletionDate: Date?
    var initialSkills: [String: [String]]
    var isCollegeLevel: Bool
    
    var branchMasteryLevels: [String: PlayerBranchMastery]
    var dungeonProgress: [String: PlayerDungeonStatus]
    
    var archivedMissions: [Mission]
    var permanentXpBoosts: [String: Double]

    // --- NEW: Stores the topic the player wants to focus on. ---
    var focusedTopicID: UUID?

    // --- FIX: Added fountainTokens property ---
    var fountainTokens: Int

    /// Calculates the number of completed missions from the archive.
    var completedMissionsCount: Int {
        archivedMissions.filter { $0.status == .completed }.count
    }


    init(username: String) {
        self.id = UUID()
        self.username = username
        
        let defaultAvatarF1 = Avatar(imageName: "avatar_f_generic_01", frameName: nil, description: "...", price: 0)
        let defaultAvatarF2 = Avatar(imageName: "avatar_f_generic_02", frameName: nil, description: "...", price: 0)
        let defaultAvatarM1 = Avatar(imageName: "avatar_m_generic_01", frameName: nil, description: "...", price: 0)
        let defaultAvatarM2 = Avatar(imageName: "avatar_m_generic_02", frameName: nil, description: "...", price: 0)
        self.currentAvatar = defaultAvatarF1
        self.unlockedAvatars = [defaultAvatarF1, defaultAvatarF2, defaultAvatarM1, defaultAvatarM2]
        
        let familiar1 = Familiar(name: "Codex", imageNamePrefix: "familiar_codex")
        let familiar2 = Familiar(name: "Gnomon", imageNamePrefix: "familiar_gnomon")
        let familiar3 = Familiar(name: "Sprout", imageNamePrefix: "familiar_sprout")
        self.unlockedFamiliars = [familiar1, familiar2, familiar3]
        self.activeFamiliar = familiar1
        
        self.unlockedTitles = []
        self.activeTitle = nil
        
        self.unlockedThemes = []
        self.unlockedFamiliarSkins = [:]
        
        self.initialSkills = [:]
        self.isCollegeLevel = false
        self.branchMasteryLevels = [:]
        self.dungeonProgress = [:]
        self.archivedMissions = []
        self.permanentXpBoosts = [:]
        self.focusedTopicID = nil
        
        self.academicTier = .foundationalApprentice
        self.stats = .default
        self.totalXP = 0.0
        self.gold = 50
        self.checkInStreak = 0
        self.lastMissionCompletionDate = nil

        // --- FIX: Initialize fountainTokens ---
        self.fountainTokens = 5
    }
}

import Foundation
import SwiftUI
import Combine

// MARK: - System Log Entry
struct LogEntry: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let color: Color

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


// MARK: - Procrastination Monster Mood
/// Represents the current mood of the Procrastination Monster.
enum MonsterMood: String {
    case content, neutral, agitated, furious
    
    /// The image associated with each mood.
    var imageName: String {
        switch self {
        case .content: return "monster_content"
        case .neutral: return "monster_neutral"
        case .agitated: return "monster_agitated"
        case .furious: return "monster_furious"
        }
    }
    
    /// The gameplay effect associated with each mood.
    var statusEffectDescription: String? {
        switch self {
        case .content: return "+5% Gold from all missions."
        case .agitated: return "-5% Gold from all missions."
        case .furious: return "-10% Gold from all missions. XP gain disabled."
        default: return nil
        }
    }
    
    /// The color to use for the mood's description text.
    var effectColor: Color {
        switch self {
        case .content: return .green
        case .agitated, .furious: return .red
        default: return .secondary
        }
    }
}


// MARK: - Main View Model
@MainActor
class MainViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var player: Player
    @Published var systemLog: [LogEntry] = []
    
    @Published var archivedMissions: [Mission] = []
    @Published var missionToReview: Mission?

    @Published var achievementManager: AchievementManager
    @Published var activeMission: Mission?
    
    @Published var isShowingAvatarSelection = false
    @Published var isShowingFamiliarSelection = false
    
    // --- NEW: Reference to the KnowledgeTreeViewModel ---
    var knowledgeTreeViewModel: KnowledgeTreeViewModel?
    
    var monsterMood: MonsterMood {
        switch player.procrastinationMonsterValue {
        case 0..<2: return .content
        case 2..<5: return .neutral
        case 5..<8: return .agitated
        default: return .furious
        }
    }

    var procrastinationMonsterScale: CGFloat {
        1.0 + (player.procrastinationMonsterValue * 0.1)
    }
    
    var isQuickMissionUnlocked: Bool {
        player.completedMissionsCount >= 10
    }

    private var achievementCancellable: AnyCancellable?
    private var familiarXpTimer: Timer?

    // MARK: - Initialization

    init(player: Player) {
        self.player = player
        self.achievementManager = AchievementManager(savedStatuses: [])
        self.archivedMissions = player.archivedMissions

        checkAndUpdateStreak()
        addLogEntry("System initialized. Welcome, \(player.username)!", color: .green)
        addLogEntry("You are currently a [\(player.academicTier.rawValue)].", color: .cyan)

        self.achievementCancellable = achievementManager.$newlyUnlocked.sink { [weak self] newAchievements in
            guard let self = self else { return }
            for achievement in newAchievements {
                self.addLogEntry("Achievement Unlocked: \(achievement.name)!", color: achievement.tier.color)
            }
        }
    }
    
    func petTheMonster() {
        guard player.procrastinationMonsterValue > 0 else {
            addLogEntry("The Procrastination Monster is already content.", color: .gray)
            return
        }
        
        let reduction = 0.5
        player.procrastinationMonsterValue = max(0, player.procrastinationMonsterValue - reduction)
        addLogEntry("You pet the Procrastination Monster. It seems a little calmer.", color: .cyan)
    }

    // MARK: - Mission Lifecycle Control

    func setActiveMission(_ mission: Mission) {
        self.activeMission = mission
        player.procrastinationMonsterValue = max(0, player.procrastinationMonsterValue - 0.5)
        startFamiliarXpTimer()
        addLogEntry("Mission Started: \(mission.topicName)", color: .green)
    }

    func pauseActiveMission() {
        self.activeMission = nil
        stopFamiliarXpTimer()
        addLogEntry("Mission Paused.", color: .orange)
    }

    func completeMission(_ mission: Mission, xpGained: Double, goldGained: Int) {
        let completedMission = mission
        completedMission.status = .completed
        completedMission.completionDate = Date()
        
        self.activeMission = nil
        stopFamiliarXpTimer()

        var finalGold = goldGained
        var finalXP = xpGained
        
        switch monsterMood {
        case .content:
            finalGold = Int(Double(finalGold) * 1.05)
        case .agitated:
            finalGold = Int(Double(finalGold) * 0.95)
        case .furious:
            finalGold = Int(Double(finalGold) * 0.90)
            finalXP = 0
        default:
            break
        }
        
        player.gold += finalGold
        player.totalXP += finalXP
        
        if let lastDate = player.lastMissionCompletionDate {
            if !Calendar.current.isDateInToday(lastDate) {
                if Calendar.current.isDateInYesterday(lastDate) {
                    player.checkInStreak += 1
                } else {
                    player.checkInStreak = 1
                }
            }
        } else {
            player.checkInStreak = 1
        }
        player.lastMissionCompletionDate = Date()
        
        // --- NEW: Add progress to the Knowledge Tree ---
        if let timeSpent = mission.actualTimeSpent, timeSpent > 0 {
            knowledgeTreeViewModel?.addProgress(
                to: mission.branchName,
                in: mission.subjectName,
                xp: finalXP,
                time: timeSpent
            )
        }

        addLogEntry("Mission Complete! +\(Int(finalXP)) XP, +\(finalGold) Gold.", color: .yellow)

        achievementManager.processEvent(.missionCompleted, for: &player)
        achievementManager.processEvent(.goldEarned(totalAmount: player.gold), for: &player)
        achievementManager.processEvent(.streakReached(days: player.checkInStreak), for: &player)
        achievementManager.processEvent(.loginTime(hour: Calendar.current.component(.hour, from: Date())), for: &player)

        if completedMission.source == .dungeon {
            handleDungeonStageCompletion(for: completedMission)
        }
        
        self.missionToReview = completedMission
    }
    
    func submitMissionReview(for mission: Mission, focus: Int, understanding: Int, challenge: String) {
        let bonusGold = 5
        player.gold += bonusGold
        addLogEntry("Review submitted! +\(bonusGold) Gold bonus.", color: .yellow)
        
        mission.focusRating = focus
        mission.understandingRating = understanding
        mission.challengeText = challenge.isEmpty ? nil : challenge
        
        archiveMission(mission)
    }

    func archiveMission(_ mission: Mission) {
        let missionToArchive = mission
        if let index = player.archivedMissions.firstIndex(where: { $0.id == mission.id }) {
             player.archivedMissions[index] = missionToArchive
        } else {
            player.archivedMissions.insert(missionToArchive, at: 0)
        }
        self.archivedMissions = player.archivedMissions
        addLogEntry("Mission '\(mission.topicName)' moved to archive.", color: .gray)
    }


    func completeTestMission() {
    }
    
    private func handleDungeonStageCompletion(for completedMission: Mission) {
        let dungeonID = completedMission.branchName
        
        guard let dungeon = DungeonList.allDungeons.first(where: { $0.id == dungeonID }),
              var progress = player.dungeonProgress[dungeonID] else {
            return
        }
        
        progress.currentStage += 1
        
        addLogEntry("Dungeon Stage Cleared: \(completedMission.topicName)!", color: .cyan)

        if progress.currentStage > dungeon.stages.count {
            progress.isCompleted = true
            
            let finalReward = dungeon.finalReward
            player.gold += finalReward.gold
            player.totalXP += finalReward.xp
            
            addLogEntry("Dungeon Complete: \(dungeon.name)! You earned a bonus of \(finalReward.gold) Gold and \(Int(finalReward.xp)) XP!", color: .yellow)
            
            if let titleID = finalReward.title, let title = TitleList.byId(titleID) {
                if !player.unlockedTitles.contains(where: { $0.id == title.id }) {
                    player.unlockedTitles.append(title)
                    addLogEntry("New Title Unlocked: \(title.name)!", color: .purple)
                }
            }
        }
        
        player.dungeonProgress[dungeonID] = progress
    }


    // MARK: - Familiar Logic

    private func startFamiliarXpTimer() {
        stopFamiliarXpTimer()
        
        familiarXpTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.grantFamiliarXp()
            }
        }
    }

    private func stopFamiliarXpTimer() {
        familiarXpTimer?.invalidate()
        familiarXpTimer = nil
    }

    private func grantFamiliarXp() {
        guard let familiarIndex = player.unlockedFamiliars.firstIndex(where: { $0.id == player.activeFamiliar.id }) else { return }

        let xpGained = 5.0
        player.unlockedFamiliars[familiarIndex].xp += xpGained
        player.activeFamiliar.xp += xpGained

        print("Familiar '\(player.activeFamiliar.name)' gained \(xpGained) XP.")
    }

    // MARK: - System Log & Streak

    func addLogEntry(_ message: String, color: Color) {
        if systemLog.count > 50 {
            systemLog.removeLast()
        }
        let newEntry = LogEntry(timestamp: Date(), message: message, color: color)
        systemLog.insert(newEntry, at: 0)
    }

    private func checkAndUpdateStreak() {
        guard let lastCompletionDate = player.lastMissionCompletionDate else {
            player.checkInStreak = 0
            return
        }
        
        if !Calendar.current.isDateInYesterday(lastCompletionDate) && !Calendar.current.isDateInToday(lastCompletionDate) {
            addLogEntry("Check-in streak has been reset to 0.", color: .red)
            player.checkInStreak = 0
        }
    }
}

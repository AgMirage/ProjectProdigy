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

    // --- EDITED: Updated function to accept explicit rewards ---
    func completeMission(_ mission: Mission, xpGained: Double, goldGained: Int) {
        let completedMission = mission
        completedMission.status = .completed
        
        self.activeMission = nil
        stopFamiliarXpTimer()

        player.gold += goldGained
        player.totalXP += xpGained
        player.lastMissionCompletionDate = Date()
        player.checkInStreak += 1

        addLogEntry("Mission Complete! +\(Int(xpGained)) XP, +\(goldGained) Gold.", color: .yellow)

        achievementManager.processEvent(.missionCompleted, for: &player)
        achievementManager.processEvent(.goldEarned(totalAmount: player.gold), for: &player)
        achievementManager.processEvent(.streakReached(days: player.checkInStreak), for: &player)
        achievementManager.processEvent(.loginTime(hour: Calendar.current.component(.hour, from: Date())), for: &player)

        if completedMission.source == .dungeon {
            handleDungeonStageCompletion(for: completedMission)
        }
        
        self.missionToReview = completedMission
    }
    
    func submitMissionReview(for missionID: UUID, focus: Int, understanding: Int, challenge: String) {
        let bonusGold = 5
        player.gold += bonusGold
        addLogEntry("Review submitted! +\(bonusGold) Gold bonus.", color: .yellow)
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
        // This function would now need to be updated if used, to pass the explicit rewards.
        // For now, we leave it as is, but it would not compile without adjustment.
        // self.completeMission(Mission.sample, xpGained: Mission.sample.xpReward, goldGained: Mission.sample.goldReward)
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
        if !Calendar.current.isDateInToday(lastCompletionDate) && !Calendar.current.isDateInYesterday(lastCompletionDate) {
            addLogEntry("Check-in streak has been reset to 0.", color: .red)
            player.checkInStreak = 0
        }
    }
}

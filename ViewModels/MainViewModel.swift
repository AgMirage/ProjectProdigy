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
    @Published var missionToReview: Mission? // For triggering the review sheet

    @Published var achievementManager: AchievementManager
    @Published var activeMission: Mission?

    var procrastinationMonsterScale: CGFloat {
        1.0 + (player.procrastinationMonsterValue * 0.1)
    }

    private var achievementCancellable: AnyCancellable?
    private var familiarXpTimer: Timer?

    // MARK: - Initialization

    init(player: Player) {
        self.player = player
        self.achievementManager = AchievementManager()
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

    func completeMission(_ mission: Mission) {
        var completedMission = mission
        completedMission.status = .completed
        
        self.activeMission = nil
        stopFamiliarXpTimer()

        player.gold += completedMission.goldReward
        player.totalXP += completedMission.xpReward
        player.lastMissionCompletionDate = Date()
        player.checkInStreak += 1

        addLogEntry("Mission Complete! +\(Int(completedMission.xpReward)) XP, +\(completedMission.goldReward) Gold.", color: .yellow)

        achievementManager.processEvent(.missionCompleted, for: &player)
        achievementManager.processEvent(.goldEarned(totalAmount: player.gold), for: &player)
        achievementManager.processEvent(.streakReached(days: player.checkInStreak), for: &player)
        achievementManager.processEvent(.loginTime(hour: Calendar.current.component(.hour, from: Date())), for: &player)

        if completedMission.source == .dungeon {
            handleDungeonStageCompletion(for: completedMission)
        }
        
        // Present the review sheet instead of archiving immediately
        self.missionToReview = completedMission
    }
    
    // --- NEW: Function to handle review submission ---
    func submitMissionReview(for missionID: UUID, focus: Int, understanding: Int, challenge: String) {
        // This function will be called by the review view.
        // For now, it just gives a small bonus.
        let bonusGold = 5
        player.gold += bonusGold
        addLogEntry("Review submitted! +\(bonusGold) Gold bonus.", color: .yellow)
    }

    func archiveMission(_ mission: Mission) {
        // This will be called after the review is submitted or skipped.
        let missionToArchive = mission
        // Find the mission in the archived list to add review data if it exists
        if let index = player.archivedMissions.firstIndex(where: { $0.id == mission.id }) {
             player.archivedMissions[index] = missionToArchive
        } else {
            player.archivedMissions.insert(missionToArchive, at: 0)
        }
        self.archivedMissions = player.archivedMissions
        addLogEntry("Mission '\(mission.topicName)' moved to archive.", color: .gray)
    }


    func completeTestMission() {
        self.completeMission(Mission.sample)
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

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

    // The MainViewModel now owns the AchievementManager for this player session.
    @Published var achievementManager: AchievementManager

    // This will hold the mission that is currently running.
    @Published var activeMission: Mission?

    // This is now a computed property based on the player's procrastination value.
    var procrastinationMonsterScale: CGFloat {
        // The scale grows slightly as the value increases from 0.
        1.0 + (player.procrastinationMonsterValue * 0.1)
    }

    private var achievementCancellable: AnyCancellable?
    private var familiarXpTimer: Timer?

    // MARK: - Initialization

    init(player: Player) {
        self.player = player
        self.achievementManager = AchievementManager()

        checkAndUpdateStreak()
        addLogEntry("System initialized. Welcome, \(player.username)!", color: .green)
        addLogEntry("You are currently a [\(player.academicTier.rawValue)].", color: .cyan)

        // Listen for newly unlocked achievements from the manager.
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

        // Reward for starting a mission by slightly reducing procrastination.
        player.procrastinationMonsterValue = max(0, player.procrastinationMonsterValue - 0.5)

        // Start giving the active familiar XP
        startFamiliarXpTimer()

        addLogEntry("Mission Started: \(mission.topicName)", color: .green)
    }

    func pauseActiveMission() {
        self.activeMission = nil // Setting to nil makes the familiar "sad"
        stopFamiliarXpTimer()
        addLogEntry("Mission Paused.", color: .orange)
    }

    func completeMission(_ mission: Mission) {
        self.activeMission = nil
        stopFamiliarXpTimer()

        // Grant Rewards
        player.gold += mission.goldReward
        player.totalXP += mission.xpReward
        player.lastMissionCompletionDate = Date()
        player.checkInStreak += 1 // A simple increment, real logic could be more complex.

        addLogEntry("Mission Complete! +\(Int(mission.xpReward)) XP, +\(mission.goldReward) Gold.", color: .yellow)

        // Process Achievements
        achievementManager.processEvent(.missionCompleted, for: &player)
        achievementManager.processEvent(.goldEarned(totalAmount: player.gold), for: &player)
        achievementManager.processEvent(.streakReached(days: player.checkInStreak), for: &player)

        let hour = Calendar.current.component(.hour, from: Date())
        achievementManager.processEvent(.loginTime(hour: hour), for: &player)
    }

    func completeTestMission() {
        // The test function now uses the real completion logic.
        self.completeMission(Mission.sample)
    }

    // MARK: - Familiar Logic

    private func startFamiliarXpTimer() {
        stopFamiliarXpTimer() // Ensure no old timers are running
        
        // --- EDITED SECTION ---
        // We schedule the timer as before, but ensure the code inside its block
        // is dispatched to the main thread to safely interact with our @MainActor class.
        familiarXpTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.grantFamiliarXp()
            }
        }
        // --- END EDITED SECTION ---
    }

    private func stopFamiliarXpTimer() {
        familiarXpTimer?.invalidate()
        familiarXpTimer = nil
    }

    private func grantFamiliarXp() {
        guard let familiarIndex = player.unlockedFamiliars.firstIndex(where: { $0.id == player.activeFamiliar.id }) else { return }

        let xpGained = 5.0
        player.unlockedFamiliars[familiarIndex].xp += xpGained
        player.activeFamiliar.xp += xpGained // Also update the active familiar copy

        print("Familiar '\(player.activeFamiliar.name)' gained \(xpGained) XP.")

        // Add level up logic here later
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

import Foundation

/// Defines the types of events that can trigger an achievement.
enum GameEvent {
    case missionCompleted
    case goldEarned(totalAmount: Int)
    case streakReached(days: Int)
    case topicUnlocked(branchName: String)
    case loginTime(hour: Int)
}


/// An observable class responsible for tracking and unlocking achievements.
@MainActor
class AchievementManager: ObservableObject {
    
    @Published var statuses: [String: PlayerAchievementStatus] = [:]
    @Published var newlyUnlocked: [Achievement] = []

    init(savedStatuses: [PlayerAchievementStatus] = []) {
        var statusDict: [String: PlayerAchievementStatus] = [:]
        
        for status in savedStatuses {
            statusDict[status.id] = status
        }
        
        for achievement in AchievementList.allAchievements {
            if statusDict[achievement.id] == nil {
                statusDict[achievement.id] = PlayerAchievementStatus(id: achievement.id, progress: 0, isUnlocked: false)
            }
        }
        
        self.statuses = statusDict
    }
    
    /// The main function that processes a game event and updates relevant achievements.
    func processEvent(_ event: GameEvent, for player: inout Player) {
        
        for achievement in AchievementList.allAchievements {
            guard !(statuses[achievement.id]?.isUnlocked ?? true) else { continue }
            
            var shouldCheckUnlock = false
            
            switch event {
            case .missionCompleted:
                if achievement.id.contains("mission") {
                    statuses[achievement.id]?.progress += 1
                    shouldCheckUnlock = true
                }
            case .goldEarned(let totalAmount):
                if achievement.id.contains("earn") {
                    statuses[achievement.id]?.progress = Double(totalAmount)
                    shouldCheckUnlock = true
                }
            case .streakReached(let days):
                if achievement.id.contains("streak") {
                    statuses[achievement.id]?.progress = Double(days)
                    shouldCheckUnlock = true
                }
            case .loginTime(let hour):
                if achievement.id == "early_bird" && hour < 8 {
                    statuses[achievement.id]?.progress = 1
                    shouldCheckUnlock = true
                }
            default:
                break
            }
            
            if shouldCheckUnlock, let currentProgress = statuses[achievement.id]?.progress, currentProgress >= achievement.goal {
                unlockAchievement(withId: achievement.id, for: &player)
            }
        }
    }
    
    /// Marks an achievement as unlocked and grants rewards.
    private func unlockAchievement(withId id: String, for player: inout Player) {
        guard let achievement = AchievementList.byId(id),
              var status = statuses[id],
              !status.isUnlocked else { return }
        
        // Update the status
        status.isUnlocked = true
        status.unlockedDate = Date()
        statuses[id] = status
        
        // Grant the gold reward to the player
        player.gold += achievement.goldReward
        
        // --- NEW TITLE REWARD LOGIC ---
        // Check if this achievement awards a title
        if let titleID = achievement.titleRewardID, let titleToAward = TitleList.byId(titleID) {
            // Add the title to the player's collection if they don't already have it
            if !player.unlockedTitles.contains(where: { $0.id == titleID }) {
                player.unlockedTitles.append(titleToAward)
                print("Title Unlocked: '\(titleToAward.name)'!")
                
                // If the player has no active title, equip this new one automatically.
                if player.activeTitle == nil {
                    player.activeTitle = titleToAward
                }
            }
        }
        // --- END NEW TITLE REWARD LOGIC ---
        
        // Add to the list of newly unlocked achievements to show a notification.
        newlyUnlocked.append(achievement)
        
        print("ACHIEVEMENT UNLOCKED: '\(achievement.name)'! Player earned \(achievement.goldReward) Gold.")
    }
}

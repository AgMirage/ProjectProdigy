import Foundation
import SwiftUI

@MainActor
class BossBattleViewModel: ObservableObject {
    
    /// The currently pending boss battle, if one exists.
    @Published var activeBossBattle: Mission?
    
    @Published var battleName: String = ""
    @Published var wagerAmount: String = ""
    @Published var selectedSubject: Subject?
    @Published var selectedBranch: KnowledgeBranch?
    @Published var battleType: BossBattleType = .finalExam
    @Published var battleDate: Date = Date()
    @Published var battleDurationHours: String = "3"
    
    /// A computed property to check if the player can declare a battle.
    var canDeclareBattle: Bool {
        guard let player = mainViewModel?.player else { return false }
        return player.completedMissionsCount >= 10
    }
    
    /// The message to display if the player cannot declare a battle.
    var gatingMessage: String? {
        if !canDeclareBattle {
            let remaining = 10 - (mainViewModel?.player.completedMissionsCount ?? 0)
            return "You must complete \(remaining) more regular mission(s) to unlock Boss Battles."
        }
        return nil
    }
    
    // Properties for showing alerts to the user
    @Published var alertItem: AlertItem?
    
    private weak var mainViewModel: MainViewModel?
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        findActiveBossBattle()
    }
    
    /// The main function to create a new Boss Battle.
    func declareNewBattle() {
        guard let player = mainViewModel?.player, let subject = selectedSubject, let branch = selectedBranch else { return }
        
        // 1. Validate the inputs
        guard !battleName.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertItem = AlertItem(title: "Invalid Name", message: "Please enter a name for your Boss Battle.")
            return
        }
        
        guard let wager = Int(wagerAmount), wager > 0 else {
            alertItem = AlertItem(title: "Invalid Wager", message: "Please enter a valid, positive number for your Gold wager.")
            return
        }
        
        guard player.gold >= wager else {
            alertItem = AlertItem(title: "Not Enough Gold", message: "You don't have enough Gold to place that wager.")
            return
        }
        
        guard let durationHours = Double(battleDurationHours), durationHours > 0 else {
            alertItem = AlertItem(title: "Invalid Duration", message: "Please enter a valid duration in hours.")
            return
        }
        
        // 2. Deduct the wager
        mainViewModel?.player.gold -= wager
        
        // 3. Create the mission
        let xpReward = Double(wager) * 5.0
        let goldJackpot = wager * 2
        let totalDuration = durationHours * 3600 // Convert hours to seconds
        
        let newBossBattle = Mission(
            id: UUID(),
            subjectName: subject.name,
            branchName: branch.name,
            topicName: battleName,
            studyType: .majorEvent,
            creationDate: Date(),
            scheduledDate: battleDate,
            totalDuration: totalDuration,
            timeRemaining: totalDuration,
            status: .pending,
            isBossBattle: true,
            goldWager: wager,
            xpReward: xpReward,
            goldReward: goldJackpot,
            battleType: battleType
        )

        self.activeBossBattle = newBossBattle
        mainViewModel?.addLogEntry("Boss Battle Declared: '\(battleName)' for \(wager) Gold!", color: .red)
        
        // 4. Clear the form
        resetForm()
    }
    
    private func resetForm() {
        self.battleName = ""
        self.wagerAmount = ""
        self.selectedSubject = nil
        self.selectedBranch = nil
        self.battleType = .finalExam
        self.battleDate = Date()
        self.battleDurationHours = "3"
    }
    
    /// Called when the player reports they passed their real-life event.
    func reportVictory() {
        guard let battle = activeBossBattle else { return }
        
        let totalReturn = (battle.goldWager ?? 0) + battle.goldReward
        mainViewModel?.player.gold += totalReturn
        mainViewModel?.player.totalXP += battle.xpReward
        
        alertItem = AlertItem(title: "Victory!", message: "Congratulations! You have won back your wager plus a jackpot of \(battle.goldReward) Gold and \(Int(battle.xpReward)) XP!")
        mainViewModel?.addLogEntry("Boss Battle Victorious! Gained \(battle.goldReward) Gold and \(Int(battle.xpReward)) XP.", color: .green)
        
        archiveAndClear(battle, didWin: true)
    }
    
    /// Called when the player reports they did not pass their real-life event.
    func reportDefeat() {
        guard let battle = activeBossBattle else { return }
        
        alertItem = AlertItem(title: "Defeat", message: "You lost your wager of \(battle.goldWager!) Gold. Better luck next time!")
        mainViewModel?.addLogEntry("Boss Battle Lost. Wager of \(battle.goldWager!) Gold has been forfeited.", color: .gray)
        
        archiveAndClear(battle, didWin: false)
    }
    
    private func archiveAndClear(_ battle: Mission, didWin: Bool) {
        // --- EDITED: Changed 'var' to 'let' to fix the warning ---
        let battleToArchive = battle
        battleToArchive.status = didWin ? .completed : .failed
        mainViewModel?.archiveMission(battleToArchive)
        self.activeBossBattle = nil
    }
    
    /// Searches the player's missions to see if a boss battle is already active.
    private func findActiveBossBattle() {
        // This would search a persistent mission list in a full app.
    }
}

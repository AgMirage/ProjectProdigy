//
//  BossBattleViewModel.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import Foundation
import SwiftUI

@MainActor
class BossBattleViewModel: ObservableObject {
    
    // The currently pending boss battle, if one exists.
    @Published var activeBossBattle: Mission?
    
    // Properties for the creation form
    @Published var battleName: String = ""
    @Published var wagerAmount: String = ""
    
    // Properties for showing alerts to the user
    @Published var alertItem: AlertItem?
    
    private weak var mainViewModel: MainViewModel?
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        findActiveBossBattle()
    }
    
    /// The main function to create a new Boss Battle.
    func declareNewBattle() {
        guard let player = mainViewModel?.player else { return }
        
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
            alertItem = AlertItem(title: "Not Enough Gold", message: "You don't have enough Gold to place that wager. Complete more missions to earn Gold.")
            return
        }
        
        // 2. Deduct the wager from the player's gold
        mainViewModel?.player.gold -= wager
        
        // 3. Create the special mission object
        // The rewards are pre-calculated for when victory is declared.
        let xpReward = Double(wager) * 5.0 // High XP reward based on wager
        let goldJackpot = wager * 2 // Player wins their wager back, plus this amount.
        
        let newBossBattle = Mission(id: UUID(), subjectName: "Boss Battle", branchName: "Real-Life Events", topicName: battleName, studyType: .majorEvent, creationDate: Date(), totalDuration: 0, timeRemaining: 0, status: .pending, isBossBattle: true, goldWager: wager, xpReward: xpReward, goldReward: goldJackpot)
        
        // 4. Add it to the active missions list and set it as the current one
        // In a real app, this would be added to a shared mission list. For now, we set it locally.
        self.activeBossBattle = newBossBattle
        mainViewModel?.addLogEntry("Boss Battle Declared: '\(battleName)' for \(wager) Gold!", color: .red)
        
        // 5. Clear the form
        self.battleName = ""
        self.wagerAmount = ""
    }
    
    /// Called when the player reports they passed their real-life event.
    func reportVictory() {
        guard let battle = activeBossBattle else { return }
        
        // The total gold returned is the original wager + the jackpot.
        let totalReturn = battle.goldWager! + battle.goldReward
        mainViewModel?.player.gold += totalReturn
        
        // Grant the XP
        mainViewModel?.player.totalXP += battle.xpReward
        
        alertItem = AlertItem(title: "Victory!", message: "Congratulations! You have won back your wager plus a jackpot of \(battle.goldReward) Gold and \(Int(battle.xpReward)) XP!")
        mainViewModel?.addLogEntry("Boss Battle Victorious! Gained \(battle.goldReward) Gold and \(Int(battle.xpReward)) XP.", color: .green)
        
        // Clear the battle
        self.activeBossBattle = nil
    }
    
    /// Called when the player reports they did not pass their real-life event.
    func reportDefeat() {
        guard let battle = activeBossBattle else { return }
        
        // The wagered gold is already deducted, so it is lost.
        alertItem = AlertItem(title: "Defeat", message: "You lost your wager of \(battle.goldWager!) Gold. Better luck next time!")
        mainViewModel?.addLogEntry("Boss Battle Lost. Wager of \(battle.goldWager!) Gold has been forfeited.", color: .gray)
        
        // Clear the battle
        self.activeBossBattle = nil
    }
    
    /// Searches the player's missions to see if a boss battle is already active.
    private func findActiveBossBattle() {
        // In a real app with persistent missions, this would search the player's mission list.
        // For our current setup, we'll assume no battles are active on launch.
        // self.activeBossBattle = mainViewModel?.player.missions.first { $0.isBossBattle }
    }
}
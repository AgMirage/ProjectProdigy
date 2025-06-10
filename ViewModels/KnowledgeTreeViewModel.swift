import Foundation
import SwiftUI

@MainActor
class KnowledgeTreeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var fullTree: [Subject] = []
    @Published var selectedSubject: Subject?
    @Published var levelFilter: BranchLevel? = nil
    
    // --- NEW: This will trigger the mastery goal sheet to appear ---
    @Published var branchToSetMastery: KnowledgeBranch?
    
    // --- FIXED: 'private' removed to make it accessible to the View layer ---
    var player: Player?
    
    // A weak reference to the MainViewModel to update the player object
    private weak var mainViewModel: MainViewModel?
    
    var filteredBranches: [KnowledgeBranch] {
        guard let subject = selectedSubject else { return [] }
        if let filter = levelFilter {
            return subject.branches.filter { $0.level == filter }
        } else {
            return subject.branches
        }
    }

    // MARK: - Initialization & Re-initialization
    init() {
        // This initializer is used by the preview.
        self.fullTree = []
    }
    
    // This is the primary initializer used by the main app view.
    func reinitialize(with mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.player = mainViewModel.player
        self.fullTree = KnowledgeTreeFactory.createFullTree()
        
        self.unlockInitialNodes()
        self.checkForAllBranchUnlocks()
        
        if self.selectedSubject == nil {
            self.selectedSubject = self.fullTree.first
        }
    }
    
    // MARK: - Public Methods
    
    func selectSubject(_ subject: Subject) {
        self.selectedSubject = subject
    }
    
    /// Adds progress from a completed mission to the relevant branch and checks for unlocks.
    func addProgress(to branchName: String, in subjectName: String, xp: Double, time: TimeInterval) {
        guard var player = self.player, let mainVM = self.mainViewModel else { return }
        
        guard let subjectIndex = fullTree.firstIndex(where: { $0.name == subjectName }),
              let branchIndex = fullTree[subjectIndex].branches.firstIndex(where: { $0.name == branchName }) else {
            print("Error: Could not find branch '\(branchName)' in subject '\(subjectName)' to add progress.")
            return
        }
        
        // Add progress to the specific branch
        fullTree[subjectIndex].branches[branchIndex].currentXP += xp
        fullTree[subjectIndex].branches[branchIndex].totalTimeSpent += time
        fullTree[subjectIndex].branches[branchIndex].missionsCompleted += 1
        
        // Update the player object in the main view model
        player.totalXP += xp
        mainVM.player = player
        self.player = player
        
        // Check for unlocks
        checkForTopicUnlocks(inBranchIndex: branchIndex, inSubjectIndex: subjectIndex)
        checkForAllBranchUnlocks()
    }
    
    // --- NEW: Called by the UI when a mastery level is chosen ---
    /// Sets the mastery goal for a branch and immediately checks if it can be unlocked.
    func setMasteryGoal(for branch: KnowledgeBranch, level: MasteryLevel) {
        guard var player = self.player, let mainVM = self.mainViewModel else { return }

        let mastery = PlayerBranchMastery(branchID: branch.name, level: level)
        player.branchMasteryLevels[branch.name] = mastery
        
        // Save the updated player object
        mainVM.player = player
        self.player = player
        
        print("Mastery goal for '\(branch.name)' set to \(level.rawValue).")
        
        // Immediately check if this new goal unlocks the branch
        checkForAllBranchUnlocks()
    }
    
    // --- NEW: Determines if the "Unlock" button should be shown ---
    /// Checks if the basic prerequisites (completion percentage, stats) are met, allowing the player to attempt an unlock.
    func canAttemptUnlock(for branch: KnowledgeBranch) -> Bool {
        guard let player = self.player else { return false }
        
        // 1. Check Stat Requirements
        if let requiredStats = branch.requiredStats {
            for (statName, requiredValue) in requiredStats {
                if player.stats.value(forName: statName) < requiredValue {
                    return false
                }
            }
        }
        
        // 2. Check Topic Completion Percentage for each Prerequisite Branch
        for prereqName in branch.prerequisiteBranchNames {
            guard let prereqBranch = findBranch(withName: prereqName) else { return false }
            
            let unlockedTopics = prereqBranch.topics.filter { $0.isUnlocked }.count
            let totalTopics = prereqBranch.topics.count
            guard totalTopics > 0 else { continue }
            
            if (Double(unlockedTopics) / Double(totalTopics)) < branch.prerequisiteCompletion {
                return false
            }
        }
        
        return true
    }

    // MARK: - Private Unlocking Logic
    
    private func checkForTopicUnlocks(inBranchIndex branchIndex: Int, inSubjectIndex subjectIndex: Int) {
        let branch = fullTree[subjectIndex].branches[branchIndex]
        guard branch.isUnlocked else { return }

        for i in 0..<branch.topics.count {
            guard !branch.topics[i].isUnlocked else { continue }
            let topic = branch.topics[i]
            
            if branch.currentXP >= topic.xpRequired &&
               branch.missionsCompleted >= topic.missionsRequired &&
               branch.totalTimeSpent >= topic.timeRequired {
                
                fullTree[subjectIndex].branches[branchIndex].topics[i].isUnlocked = true
                print("TOPIC UNLOCKED: '\(topic.name)' in branch '\(branch.name)'")
            }
        }
    }
    
    private func checkForAllBranchUnlocks() {
        for subjectIndex in 0..<fullTree.count {
            for branchIndex in 0..<fullTree[subjectIndex].branches.count {
                let branch = fullTree[subjectIndex].branches[branchIndex]
                guard !branch.isUnlocked else { continue }

                if arePrerequisitesMet(for: branch) {
                    fullTree[subjectIndex].branches[branchIndex].isUnlocked = true
                    if !fullTree[subjectIndex].branches[branchIndex].topics.isEmpty {
                        fullTree[subjectIndex].branches[branchIndex].topics[0].isUnlocked = true
                    }
                    print("MAIN BRANCH UNLOCKED: '\(branch.name)'")
                }
            }
        }
    }
    
    // --- UPDATED: This function is now "Mastery-Aware" ---
    /// Checks all conditions required to unlock a main branch, applying mastery multipliers.
    private func arePrerequisitesMet(for branch: KnowledgeBranch) -> Bool {
        guard let player = self.player else { return false }
        
        // Get the chosen mastery level, defaulting to standard
        let masteryLevel = player.branchMasteryLevels[branch.name]?.level ?? .standard
        let multiplier = masteryLevel.multiplier
        
        // Check if the basic attempt conditions are met first
        guard canAttemptUnlock(for: branch) else { return false }
        
        // Calculate cumulative progress from prerequisite branches
        var cumulativeXP: Double = 0
        var cumulativeMissions: Int = 0
        var cumulativeTime: TimeInterval = 0
        
        for prereqName in branch.prerequisiteBranchNames {
            guard let prereqBranch = findBranch(withName: prereqName) else { return false }
            cumulativeXP += prereqBranch.currentXP
            cumulativeMissions += prereqBranch.missionsCompleted
            cumulativeTime += prereqBranch.totalTimeSpent
        }
        
        // Check progress against the *multiplied* requirements
        let requiredXP = branch.totalXpRequired * multiplier
        let requiredMissions = Int(Double(branch.totalMissionsRequired) * multiplier)
        let requiredTime = branch.totalTimeRequired * multiplier
        
        if cumulativeXP >= requiredXP &&
           cumulativeMissions >= requiredMissions &&
           cumulativeTime >= requiredTime {
            return true
        }
        
        return false
    }

    // MARK: - Initial Setup Logic
    
    private func unlockInitialNodes() {
        guard let initialSkillDict = self.player?.initialSkills else { return }

        for (subjectName, branchNames) in initialSkillDict {
            for branchName in branchNames {
                unlockBranchAndPrerequisites(branchName: branchName, inSubjectName: subjectName)
            }
        }
    }
    
    private func unlockBranchAndPrerequisites(branchName: String, inSubjectName subjectName: String) {
        guard let subjectIndex = fullTree.firstIndex(where: { $0.name == subjectName }),
              let branchIndex = fullTree[subjectIndex].branches.firstIndex(where: { $0.name == branchName }) else {
            return
        }
        
        guard !fullTree[subjectIndex].branches[branchIndex].isUnlocked else { return }
        fullTree[subjectIndex].branches[branchIndex].isUnlocked = true
        
        for topicIndex in 0..<fullTree[subjectIndex].branches[branchIndex].topics.count {
            fullTree[subjectIndex].branches[branchIndex].topics[topicIndex].isUnlocked = true
        }
        
        for prereqName in fullTree[subjectIndex].branches[branchIndex].prerequisiteBranchNames {
            if let prereqParentSubjectName = findSubjectName(forBranch: prereqName) {
                unlockBranchAndPrerequisites(branchName: prereqName, inSubjectName: prereqParentSubjectName)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func findBranch(withName name: String) -> KnowledgeBranch? {
        for subject in fullTree {
            if let branch = subject.branches.first(where: { $0.name == name }) {
                return branch
            }
        }
        return nil
    }
    
    private func findSubjectName(forBranch branchName: String) -> String? {
        for subject in fullTree {
            if subject.branches.contains(where: { $0.name == branchName }) {
                return subject.name
            }
        }
        return nil
    }
}

extension Stats {
    func value(forName statName: String) -> Int {
        switch statName.lowercased() {
        case "intelligence": return self.intelligence
        case "wisdom": return self.wisdom
        case "dexterity": return self.dexterity
        case "creativity": return self.creativity
        case "stamina": return self.stamina
        case "focus": return self.focus
        default: return 0
        }
    }
}

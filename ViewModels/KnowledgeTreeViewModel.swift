import Foundation
import SwiftUI

@MainActor
class KnowledgeTreeViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var subjects: [Subject] = []
    @Published var branchesToDisplay: [KnowledgeBranch] = []
    
    @Published var selectedSubject: Subject? {
        didSet {
            updateDisplayedBranches()
        }
    }
    @Published var levelFilter: BranchLevel? = nil {
        didSet {
            updateDisplayedBranches()
        }
    }
    @Published var branchToSetMastery: KnowledgeBranch?
    
    // --- Re-introducing refreshID to force UI updates reliably ---
    @Published var refreshID = UUID()
    
    private var fullTree: [Subject] = []
    var player: Player?
    private weak var mainViewModel: MainViewModel?

    // MARK: - Initialization
    init() { }
    
    func reinitialize(with mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.player = mainViewModel.player
        self.fullTree = KnowledgeTreeFactory.createFullTree()
        self.unlockInitialNodes()
        self.subjects = self.fullTree
        if self.selectedSubject == nil {
            self.selectedSubject = self.fullTree.first
        }
        updateDisplayedBranches()
    }
    
    // MARK: - Core Logic
    
    private func updateDisplayedBranches() {
        guard let selectedSubject = selectedSubject,
              let subjectFromTree = fullTree.first(where: { $0.id == selectedSubject.id })
        else {
            branchesToDisplay = []
            return
        }

        if let filter = levelFilter {
            branchesToDisplay = subjectFromTree.branches.filter { $0.level == filter }
        } else {
            branchesToDisplay = subjectFromTree.branches
        }
    }
    
    func addProgress(to branchName: String, in subjectName: String, xp: Double, time: TimeInterval) {
        guard var player = self.player, let mainVM = self.mainViewModel else { return }
        
        guard let sIndex = fullTree.firstIndex(where: { $0.name == subjectName }),
              let bIndex = fullTree[sIndex].branches.firstIndex(where: { $0.name == branchName }) else {
            return
        }
        
        fullTree[sIndex].branches[bIndex].currentXP += xp
        fullTree[sIndex].branches[bIndex].totalTimeSpent += time
        fullTree[sIndex].branches[bIndex].missionsCompleted += 1
        
        player.totalXP += xp
        mainVM.player = player
        self.player = player
        
        checkForTopicUnlocks(inBranchIndex: bIndex, inSubjectIndex: sIndex)
        updateDisplayedBranches()
        refreshID = UUID() // Force refresh
    }

    func setMasteryGoal(for branch: KnowledgeBranch, level: MasteryLevel) {
        guard var player = self.player, let mainVM = self.mainViewModel else { return }
        guard let (sIndex, bIndex) = findBranchIndices(for: branch.id) else { return }

        let mastery = PlayerBranchMastery(branchID: branch.name, level: level)
        player.branchMasteryLevels[branch.name] = mastery
        mainVM.player = player
        self.player = player

        if !fullTree[sIndex].branches[bIndex].isUnlocked && arePrerequisitesMet(for: fullTree[sIndex].branches[bIndex]) {
            fullTree[sIndex].branches[bIndex].isUnlocked = true
        }
        
        updateDisplayedBranches()
        refreshID = UUID() // Force refresh
    }
    
    func canAttemptUnlock(for branch: KnowledgeBranch) -> Bool {
        guard self.player != nil else { return false }

        if branch.prerequisiteBranchNames.isEmpty { return true }
        
        if let requiredStats = branch.requiredStats {
            for (statName, requiredValue) in requiredStats {
                if player!.stats.value(forName: statName) < requiredValue { return false }
            }
        }
        
        for prereqName in branch.prerequisiteBranchNames {
            guard let prereqBranch = findBranch(withName: prereqName), prereqBranch.isUnlocked else {
                return false
            }
            if prereqBranch.progress < branch.prerequisiteCompletion {
                return false
            }
        }
        return true
    }
    
    func resetSubjectProgress(subjectID: UUID) {
        guard let sIndex = fullTree.firstIndex(where: { $0.id == subjectID }) else { return }
        for branch in fullTree[sIndex].branches {
            if branch.isUnlocked {
                resetBranchProgress(branchID: branch.id, shouldUpdateView: false)
            }
        }
        updateDisplayedBranches()
        refreshID = UUID() // Force refresh
    }
    
    func resetBranchProgress(branchID: UUID, shouldUpdateView: Bool = true) {
        guard let (sIndex, bIndex) = findBranchIndices(for: branchID) else { return }
        
        fullTree[sIndex].branches[bIndex].currentXP = 0
        fullTree[sIndex].branches[bIndex].totalTimeSpent = 0
        fullTree[sIndex].branches[bIndex].missionsCompleted = 0
        
        for i in 0..<fullTree[sIndex].branches[bIndex].topics.count {
            fullTree[sIndex].branches[bIndex].topics[i].isUnlocked = false
        }
        
        if shouldUpdateView {
            updateDisplayedBranches()
            refreshID = UUID() // Force refresh
        }
    }
    
    func resetTopicProgress(topicID: UUID) {
        guard let (sIndex, bIndex, tIndex) = findTopicIndices(for: topicID) else { return }
        guard fullTree[sIndex].branches[bIndex].topics[tIndex].isUnlocked else { return }
        
        let topicToReset = fullTree[sIndex].branches[bIndex].topics[tIndex]
        fullTree[sIndex].branches[bIndex].topics[tIndex].isUnlocked = false
        
        fullTree[sIndex].branches[bIndex].currentXP -= topicToReset.xpRequired
        fullTree[sIndex].branches[bIndex].missionsCompleted -= topicToReset.missionsRequired
        fullTree[sIndex].branches[bIndex].totalTimeSpent -= topicToReset.timeRequired
        
        updateDisplayedBranches()
        refreshID = UUID() // Force refresh
    }

    // MARK: - Private Helper Functions
    
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
            }
        }
    }
    
    private func arePrerequisitesMet(for branch: KnowledgeBranch) -> Bool {
        return canAttemptUnlock(for: branch)
    }
    
    private func unlockInitialNodes() {
        guard let initialSkillDict = self.player?.initialSkills else { return }
        for (subjectName, branchNames) in initialSkillDict {
            for branchName in branchNames {
                unlockBranchAndPrerequisites(branchName: branchName, inSubjectName: subjectName, isAuto: true)
            }
        }
    }
    
    private func unlockBranchAndPrerequisites(branchName: String, inSubjectName subjectName: String, isAuto: Bool) {
        guard let (sIndex, bIndex) = findBranchIndices(forBranchName: branchName, inSubjectName: subjectName) else { return }
        guard !fullTree[sIndex].branches[bIndex].isUnlocked else { return }
        
        var branch = fullTree[sIndex].branches[bIndex]
        branch.isUnlocked = true
        branch.isAutoUnlocked = isAuto
        
        if isAuto {
            for i in 0..<branch.topics.count {
                branch.topics[i].isUnlocked = true
            }
        }
        fullTree[sIndex].branches[bIndex] = branch
        
        for prereqName in fullTree[sIndex].branches[bIndex].prerequisiteBranchNames {
            if let prereqParentSubjectName = findSubjectName(forBranch: prereqName) {
                unlockBranchAndPrerequisites(branchName: prereqName, inSubjectName: prereqParentSubjectName, isAuto: isAuto)
            }
        }
    }
    
    private func findBranch(withName name: String) -> KnowledgeBranch? {
        for subject in fullTree {
            if let branch = subject.branches.first(where: { $0.name == name }) {
                return branch
            }
        }
        return nil
    }

    private func findBranchIndices(for branchID: UUID) -> (Int, Int)? {
        for (sIndex, subject) in fullTree.enumerated() {
            if let bIndex = subject.branches.firstIndex(where: { $0.id == branchID }) {
                return (sIndex, bIndex)
            }
        }
        return nil
    }
    
    private func findTopicIndices(for topicID: UUID) -> (Int, Int, Int)? {
        for (sIndex, subject) in fullTree.enumerated() {
            for (bIndex, branch) in subject.branches.enumerated() {
                if let tIndex = branch.topics.firstIndex(where: { $0.id == topicID }) {
                    return (sIndex, bIndex, tIndex)
                }
            }
        }
        return nil
    }
    
    private func findBranchIndices(forBranchName branchName: String, inSubjectName subjectName: String) -> (Int, Int)? {
        guard let sIndex = fullTree.firstIndex(where: { $0.name == subjectName }) else { return nil }
        guard let bIndex = fullTree[sIndex].branches.firstIndex(where: { $0.name == branchName }) else { return nil }
        return (sIndex, bIndex)
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

import Foundation
import Combine

@MainActor
class MissionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activeMissions: [Mission] = []
    @Published var isShowingCreateSheet = false
    
    // Filter State Properties
    @Published var statusFilter: MissionStatus? = nil
    @Published var sourceFilter: MissionSource? = nil
    
    // Form Properties
    @Published var selectedSubject: Subject?
    @Published var selectedBranch: KnowledgeBranch?
    @Published var selectedTopic: KnowledgeTopic?
    @Published var selectedStudyType: StudyType?
    @Published var missionHours: Int = 0
    @Published var missionMinutes: Int = 30
    @Published var isPomodoroEnabled: Bool = false
    @Published var scheduledDate: Date?

    // --- EDITED: This is now a published property to be shared with the Settings view. ---
    @Published var dailyMissionSettings = DailyMissionSettings.default

    var filteredAndSortedMissions: [Mission] {
        var missions = activeMissions

        if let statusFilter = statusFilter {
            missions = missions.filter { $0.status == statusFilter }
        }
        if let sourceFilter = sourceFilter {
            missions = missions.filter { $0.source == sourceFilter }
        }
        
        missions.sort {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.creationDate > $1.creationDate
        }
        
        return missions
    }
    
    var availableStudyTypes: [StudyType] {
        guard let category = selectedSubject?.category else { return [] }
        return StudyType.allCases.filter { $0.categories.contains(category) }
    }
    
    var knowledgeTree: [Subject] = []
    
    private var timer: AnyCancellable?
    private weak var mainViewModel: MainViewModel?

    private let pomodoroStudyDuration: TimeInterval = 25 * 60
    private let pomodoroBreakDuration: TimeInterval = 5 * 60

    // MARK: - Initialization
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.knowledgeTree = KnowledgeTreeFactory.createFullTree()
        resetForm()
        
        let dailyManager = DailyMissionManager(settings: dailyMissionSettings)
        let newDailyMissions = dailyManager.generateMissionsForToday(knowledgeTree: self.knowledgeTree)
        self.dailyMissionSettings = dailyManager.settings
        self.activeMissions.append(contentsOf: newDailyMissions)
    }
    
    // MARK: - Reward Calculation
    
    private func calculateRewards(
        for subject: Subject,
        branch: KnowledgeBranch,
        studyType: StudyType,
        duration: TimeInterval,
        player: Player
    ) -> (xp: Double, gold: Int) {
        var baseXP = (duration / 60) * 2.5
        var baseGold = Int((duration / 60) * 0.5)

        if branch.level == .college {
            baseXP *= 1.2
            baseGold = Int(Double(baseGold) * 1.2)
        }

        switch studyType {
        case .derivations, .designingExperiment, .writingEssay:
            baseXP *= 1.3
        case .reviewingNotes, .watchingVideo:
            baseXP *= 0.9
        default:
            break
        }

        if subject.category == .stem && player.stats.intelligence > 10 {
            let bonus = Double(player.stats.intelligence - 10) * 0.02
            baseXP *= (1.0 + bonus)
        }

        return (xp: max(1, baseXP), gold: max(1, baseGold))
    }

    
    // MARK: - Mission Creation & Lifecycle
    
    func createMission() {
        guard let subject = selectedSubject,
              let branch = selectedBranch,
              let topic = selectedTopic,
              let studyType = selectedStudyType,
              let player = mainViewModel?.player else { return }
        
        let totalDuration = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        let initialTimeRemaining = isPomodoroEnabled ? pomodoroStudyDuration : totalDuration
        
        let rewards = calculateRewards(
            for: subject,
            branch: branch,
            studyType: studyType,
            duration: totalDuration,
            player: player
        )
        
        var newMission = Mission(id: UUID(), subjectName: subject.name, branchName: branch.name, topicName: topic.name, studyType: studyType, creationDate: Date(), totalDuration: totalDuration, timeRemaining: initialTimeRemaining, status: .pending, isPomodoro: isPomodoroEnabled, xpReward: rewards.xp, goldReward: rewards.gold)
        newMission.scheduledDate = self.scheduledDate
        
        activeMissions.append(newMission)
        isShowingCreateSheet = false
        resetForm()
    }
    
    /// --- NEW: Quick Mission Generation ---
    func generateQuickMission() {
        guard let player = mainViewModel?.player,
              let (topic, branchName, subjectName) = findRandomUnlockedTopic(in: knowledgeTree) else {
            mainViewModel?.addLogEntry("Could not generate Quick Mission. Unlock more topics first!", color: .orange)
            return
        }
        
        let duration: TimeInterval = 600 // 10 minutes
        let subject = knowledgeTree.first(where: { $0.name == subjectName })!
        let branch = subject.branches.first(where: { $0.name == branchName })!
        
        let rewards = calculateRewards(for: subject, branch: branch, studyType: .reviewingNotes, duration: duration, player: player)
        
        let quickMission = Mission(
            id: UUID(),
            subjectName: subjectName,
            branchName: branchName,
            topicName: topic.name,
            studyType: .reviewingNotes, // Default to a simple type
            creationDate: Date(),
            totalDuration: duration,
            timeRemaining: duration,
            status: .pending,
            xpReward: rewards.xp,
            goldReward: rewards.gold,
            source: .automatic // Using automatic for now, could be its own source
        )
        
        activeMissions.insert(quickMission, at: 0)
        mainViewModel?.addLogEntry("Quick Mission generated: \(topic.name)!", color: .purple)
    }

    
    func createMission(from stage: DungeonStage, in dungeon: Dungeon) {
        let topicName = "Dungeon: \(stage.name)"
        let duration = stage.requiredDuration
        let xpReward = (duration / 60) * 2.5
        let goldReward = Int((duration / 60) * 0.5)

        let newMission = Mission(id: UUID(), subjectName: dungeon.subjectName, branchName: dungeon.name, topicName: topicName, studyType: stage.studyType, creationDate: Date(), totalDuration: duration, timeRemaining: duration, status: .pending, xpReward: xpReward, goldReward: goldReward, source: .dungeon)
        
        activeMissions.append(newMission)
    }
    
    func startMission(mission: Mission) {
        guard let index = activeMissions.firstIndex(where: { $0.id == mission.id }) else { return }
        stopAllMissions()
        
        var missionToStart = activeMissions[index]
        missionToStart.allowedPauseTime = missionToStart.totalDuration * 0.1
        activeMissions[index] = missionToStart
        
        if activeMissions[index].isPomodoro {
            if activeMissions[index].pomodoroCycle == 0 {
                activeMissions[index].pomodoroCycle = 1
                activeMissions[index].timeRemaining = pomodoroStudyDuration
            }
        }
        
        activeMissions[index].status = .inProgress
        mainViewModel?.setActiveMission(activeMissions[index])
        
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.updateTimer() }
    }
    
    func pauseMission(mission: Mission) {
        guard let index = activeMissions.firstIndex(where: { $0.id == mission.id }) else { return }
        
        var missionToPause = activeMissions[index]
        if let allowedTime = missionToPause.allowedPauseTime, missionToPause.timePaused < allowedTime {
             // Future logic can go here
        }
        missionToPause.status = .paused
        activeMissions[index] = missionToPause
        
        mainViewModel?.pauseActiveMission()
        timer?.cancel()
    }
    
    func completeMission(mission: Mission) {
        timer?.cancel()
        mainViewModel?.completeMission(mission)
        activeMissions.removeAll { $0.id == mission.id }
    }
    
    func deleteMission(at offsets: IndexSet) {
        activeMissions.remove(atOffsets: offsets)
    }
    
    func togglePin(for mission: Mission) {
        guard let index = activeMissions.firstIndex(where: { $0.id == mission.id }) else { return }
        activeMissions[index].isPinned.toggle()
    }

    func resetForm() {
        selectedSubject = nil; selectedBranch = nil; selectedTopic = nil; selectedStudyType = nil; missionHours = 0; missionMinutes = 30; isPomodoroEnabled = false; scheduledDate = nil
    }
    
    private func stopAllMissions() {
        timer?.cancel()
        for i in 0..<activeMissions.count { if activeMissions[i].status == .inProgress { activeMissions[i].status = .paused } }
    }
    
    private func updateTimer() {
        guard let activeIndex = activeMissions.firstIndex(where: { $0.status == .inProgress }) else {
            timer?.cancel()
            return
        }
        
        if activeMissions[activeIndex].status == .paused {
            activeMissions[activeIndex].timePaused += 1
            return
        }
        
        if activeMissions[activeIndex].timeRemaining > 0 {
            activeMissions[activeIndex].timeRemaining -= 1
        }
        
        guard activeMissions[activeIndex].timeRemaining <= 0 else { return }
            
        var mission = activeMissions[activeIndex]
        
        if mission.isPomodoro {
            if mission.isBreakTime {
                mission.isBreakTime = false; mission.pomodoroCycle += 1; mission.timeRemaining = pomodoroStudyDuration
                mainViewModel?.addLogEntry("Break's over! Starting Focus Cycle \(mission.pomodoroCycle).", color: .green)
                mainViewModel?.setActiveMission(mission)
            } else {
                let totalStudyTimeSoFar = Double(mission.pomodoroCycle) * pomodoroStudyDuration
                if totalStudyTimeSoFar >= mission.totalDuration {
                    completeMission(mission: mission); return
                } else {
                    mission.isBreakTime = true; mission.timeRemaining = pomodoroBreakDuration
                    mainViewModel?.addLogEntry("Focus Cycle complete! Time for a short break.", color: .blue)
                    mainViewModel?.pauseActiveMission()
                }
            }
            activeMissions[activeIndex] = mission
        } else {
            if mission.timeRemaining <= 0 {
                activeMissions[activeIndex].status = .failed
                mainViewModel?.addLogEntry("Mission Failed: \(mission.topicName)", color: .red)
                timer?.cancel()
            } else {
                completeMission(mission: activeMissions[activeIndex])
            }
        }
    }
    
    /// Finds a random, unlocked topic from the entire knowledge tree.
    private func findRandomUnlockedTopic(in tree: [Subject]) -> (topic: KnowledgeTopic, branchName: String, subjectName: String)? {
        let allUnlockedBranches = tree.flatMap { subject in
            subject.branches
                .filter { $0.isUnlocked }
                .map { (branch: $0, subjectName: subject.name) }
        }
        
        guard !allUnlockedBranches.isEmpty else { return nil }
        
        let randomBranchInfo = allUnlockedBranches.randomElement()!
        
        let unlockedTopics = randomBranchInfo.branch.topics.filter { $0.isUnlocked }
        
        guard let randomTopic = unlockedTopics.randomElement() else { return nil }
        
        return (topic: randomTopic, branchName: randomBranchInfo.branch.name, subjectName: randomBranchInfo.subjectName)
    }
}

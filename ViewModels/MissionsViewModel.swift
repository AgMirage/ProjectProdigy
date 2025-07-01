import Foundation
import Combine

// Enum for the view's tabs
enum MissionListTab: String, CaseIterable {
    case active = "Active"
    case scheduled = "Scheduled"
    case completed = "Completed"
}


@MainActor
class MissionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activeMissions: [Mission] = []
    @Published var isShowingCreateSheet = false
    
    @Published var selectedTab: MissionListTab = .active
    @Published var sourceFilter: MissionSource? = nil
    
    @Published var selectedSubject: Subject?
    @Published var selectedBranch: KnowledgeBranch?
    @Published var selectedTopic: KnowledgeTopic?
    @Published var selectedStudyType: StudyType?
    @Published var missionHours: Int = 0
    @Published var missionMinutes: Int = 30
    @Published var isPomodoroEnabled: Bool = false
    @Published var scheduledDate: Date?

    @Published var dailyMissionSettings = DailyMissionSettings.default
    
    // --- NEW: Properties for conflict detection ---
    @Published var conflictingMission: Mission?
    @Published var showConflictAlert = false

    var canEnablePomodoro: Bool {
        let totalDuration = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        return totalDuration >= dailyMissionSettings.pomodoroStudyDuration
    }
    
    var pomodoroRequirementMessage: String {
        let requiredMinutes = Int(dailyMissionSettings.pomodoroStudyDuration / 60)
        return "Mission must be at least \(requiredMinutes) minutes to use Pomodoro mode."
    }
    
    var filteredAndSortedMissions: [Mission] {
        var missions: [Mission]

        switch selectedTab {
        case .active:
            missions = activeMissions.filter {
                $0.status == .inProgress || $0.status == .paused || $0.status == .pending
            }
        case .scheduled:
            missions = activeMissions.filter { $0.status == .scheduled }
        case .completed:
            return []
        }

        if let sourceFilter = sourceFilter {
            missions = missions.filter { $0.source == sourceFilter }
        }
        
        missions.sort {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            if $0.status == .scheduled && $1.status == .scheduled {
                return ($0.scheduledDate ?? Date()) < ($1.scheduledDate ?? Date())
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
    private var scheduleCheckTimer: AnyCancellable?
    private weak var mainViewModel: MainViewModel?
    
    // MARK: - Initialization
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.knowledgeTree = KnowledgeTreeFactory.createFullTree()
        resetForm()
        
        let dailyManager = DailyMissionManager(settings: dailyMissionSettings)
        let newDailyMissions = dailyManager.generateMissionsForToday(knowledgeTree: self.knowledgeTree)
        self.dailyMissionSettings = dailyManager.settings
        self.activeMissions.append(contentsOf: newDailyMissions)
        
        self.scheduleCheckTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForScheduledMissions()
            }
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
    
    /// The first step of mission creation. Checks for conflicts before proceeding.
    func createMission() {
        // --- NEW: Conflict Check ---
        if let scheduledDate = self.scheduledDate {
            let newMissionDuration = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
            let newMissionEnd = scheduledDate.addingTimeInterval(newMissionDuration)

            for existingMission in activeMissions where existingMission.status == .scheduled {
                if let existingStart = existingMission.scheduledDate {
                    let existingEnd = existingStart.addingTimeInterval(existingMission.totalDuration)
                    // Check for overlap: (StartA < EndB) and (EndA > StartB)
                    if scheduledDate < existingEnd && newMissionEnd > existingStart {
                        // Conflict found, show an alert.
                        self.conflictingMission = existingMission
                        self.showConflictAlert = true
                        return
                    }
                }
            }
        }
        
        // No conflict, proceed with creation.
        proceedWithMissionCreation()
    }
    
    /// The second step of mission creation, called after the conflict check passes or is overridden by the user.
    func proceedWithMissionCreation() {
        guard let subject = selectedSubject,
              let branch = selectedBranch,
              let topic = selectedTopic,
              let studyType = selectedStudyType,
              let player = mainViewModel?.player else { return }
        
        let totalDuration = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        let initialTimeRemaining = totalDuration
        
        let rewards = calculateRewards(
            for: subject,
            branch: branch,
            studyType: studyType,
            duration: totalDuration,
            player: player
        )
        
        let newStatus: MissionStatus = (self.scheduledDate != nil && self.scheduledDate! > Date()) ? .scheduled : .pending
        
        let newMission = Mission(
            id: UUID(),
            subjectName: subject.name,
            branchName: branch.name,
            topicName: topic.name,
            studyType: studyType,
            creationDate: Date(),
            scheduledDate: self.scheduledDate,
            totalDuration: totalDuration,
            timeRemaining: initialTimeRemaining,
            status: newStatus,
            isPomodoro: isPomodoroEnabled,
            xpReward: rewards.xp,
            goldReward: rewards.gold
        )
        
        activeMissions.append(newMission)
        isShowingCreateSheet = false
        resetForm()
    }

    
    func generateQuickMission() {
        guard let player = mainViewModel?.player,
              let (topic, branchName, subjectName) = findRandomUnlockedTopic(in: knowledgeTree) else {
            mainViewModel?.addLogEntry("Could not generate Quick Mission. Unlock more topics first!", color: .orange)
            return
        }
        
        let duration: TimeInterval = 600
        let subject = knowledgeTree.first(where: { $0.name == subjectName })!
        let branch = subject.branches.first(where: { $0.name == branchName })!
        
        let rewards = calculateRewards(for: subject, branch: branch, studyType: .reviewingNotes, duration: duration, player: player)
        
        let quickMission = Mission(
            id: UUID(),
            subjectName: subjectName,
            branchName: branchName,
            topicName: topic.name,
            studyType: .reviewingNotes,
            creationDate: Date(),
            totalDuration: duration,
            timeRemaining: duration,
            status: .pending,
            xpReward: rewards.xp,
            goldReward: rewards.gold,
            source: .automatic
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
        stopAllMissions()
        
        if mission.status == .scheduled {
            mainViewModel?.addLogEntry("Your scheduled mission \"\(mission.topicName)\" is starting now!", color: .cyan)
        }
        
        if mission.status == .pending {
            if mission.isPomodoro {
                mission.timeRemaining = min(mission.totalDuration, dailyMissionSettings.pomodoroStudyDuration)
                if mission.pomodoroCycle == 0 {
                    mission.pomodoroCycle = 1
                }
            }
        }
        
        mission.status = .inProgress
        mainViewModel?.setActiveMission(mission)
        
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.updateTimer() }
    }
    
    func pauseMission(mission: Mission) {
        mission.status = .paused
        mainViewModel?.pauseActiveMission()
        timer?.cancel()
    }
    
    func completeMission(mission: Mission) {
        timer?.cancel()
        mainViewModel?.completeMission(mission, xpGained: mission.xpReward, goldGained: mission.goldReward)
        activeMissions.removeAll { $0.id == mission.id }
    }
    
    func acceptCycleBonus(mission: Mission) {
        mission.isEligibleForCycleBonus = false
        mission.isFinishingForBonus = true
        mission.status = .inProgress
        mainViewModel?.setActiveMission(mission)
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in self?.updateTimer() }
    }
    
    func completeMissionForBonus(mission: Mission) {
        timer?.cancel()
        
        let bonusXP = mission.xpReward * 1.10
        let bonusGold = Int(Double(mission.goldReward) * 1.10)
        
        let bonusMission = Mission(
            id: mission.id, subjectName: mission.subjectName, branchName: mission.branchName, topicName: mission.topicName,
            studyType: mission.studyType, creationDate: mission.creationDate, scheduledDate: mission.scheduledDate,
            totalDuration: mission.totalDuration, timeRemaining: 0, status: .completed, isPomodoro: mission.isPomodoro,
            pomodoroCycle: mission.pomodoroCycle, isBreakTime: mission.isBreakTime, isBossBattle: mission.isBossBattle,
            goldWager: mission.goldWager, xpReward: bonusXP, goldReward: bonusGold, source: mission.source,
            isPinned: mission.isPinned, difficulty: mission.difficulty
        )
        
        mainViewModel?.addLogEntry("Focus cycle finished! +10% Rewards!", color: .yellow)
        mainViewModel?.completeMission(bonusMission, xpGained: bonusXP, goldGained: bonusGold)
        activeMissions.removeAll { $0.id == mission.id }
    }
    
    func retryMission(mission: Mission) {
        mission.status = .pending
        if mission.isPomodoro {
            let customStudyDuration = dailyMissionSettings.pomodoroStudyDuration
            mission.timeRemaining = min(mission.totalDuration, customStudyDuration)
        } else {
            mission.timeRemaining = mission.totalDuration
        }
        mission.pomodoroCycle = 0
        mission.isBreakTime = false
    }
    
    func deleteMission(at offsets: IndexSet) {
        let missionsToDelete = offsets.map { filteredAndSortedMissions[$0] }
        activeMissions.removeAll { mission in
            missionsToDelete.contains(where: { $0.id == mission.id })
        }
    }
    
    func togglePin(for mission: Mission) {
        mission.isPinned.toggle()
        activeMissions.sort {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.creationDate > $1.creationDate
        }
    }

    func resetForm() {
        selectedSubject = nil; selectedBranch = nil; selectedTopic = nil; selectedStudyType = nil; missionHours = 0; missionMinutes = 30; isPomodoroEnabled = false; scheduledDate = nil
    }
    
    private func stopAllMissions() {
        timer?.cancel()
        for mission in activeMissions where mission.status == .inProgress {
            mission.status = .paused
        }
    }
    
    private func checkForScheduledMissions() {
        for mission in activeMissions where mission.status == .scheduled {
            if let scheduledDate = mission.scheduledDate, scheduledDate <= Date() {
                startMission(mission: mission)
            }
        }
    }
    
    private func updateTimer() {
        guard let mission = activeMissions.first(where: { $0.status == .inProgress }) else {
            timer?.cancel()
            return
        }
        
        if mission.timeRemaining > 0 {
            mission.timeRemaining -= 1
        }
        
        let studyDuration = dailyMissionSettings.pomodoroStudyDuration
        let completedCyclesTime = Double(mission.pomodoroCycle - 1) * studyDuration
        let currentCycleProgress = studyDuration - mission.timeRemaining
        let totalTimeStudied = completedCyclesTime + currentCycleProgress

        if mission.isPomodoro && !mission.isBreakTime && !mission.isFinishingForBonus && totalTimeStudied >= mission.totalDuration {
            mission.isEligibleForCycleBonus = true
            pauseMission(mission: mission)
            return
        }

        guard mission.timeRemaining <= 0 else {
            return
        }

        if mission.isPomodoro {
            if mission.isFinishingForBonus {
                completeMissionForBonus(mission: mission)
                return
            }
            
            if mission.isBreakTime {
                mission.isBreakTime = false
                mission.pomodoroCycle += 1
                
                let remainingTotalDuration = mission.totalDuration - (Double(mission.pomodoroCycle - 1) * dailyMissionSettings.pomodoroStudyDuration)
                mission.timeRemaining = min(remainingTotalDuration, dailyMissionSettings.pomodoroStudyDuration)

                mainViewModel?.addLogEntry("Break's over! Starting Focus Cycle \(mission.pomodoroCycle).", color: .green)
                startMission(mission: mission)
            } else {
                let totalStudyTimeCompleted = Double(mission.pomodoroCycle) * dailyMissionSettings.pomodoroStudyDuration
                if totalStudyTimeCompleted >= mission.totalDuration {
                    completeMission(mission: mission)
                } else {
                    mission.isBreakTime = true
                    mission.timeRemaining = dailyMissionSettings.pomodoroBreakDuration
                    mainViewModel?.addLogEntry("Focus Cycle complete! Time for a short break.", color: .blue)
                    pauseMission(mission: mission)
                }
            }
        } else {
            completeMission(mission: mission)
        }
    }
    
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

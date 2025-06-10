import Foundation
import Combine

@MainActor
class MissionsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activeMissions: [Mission] = []
    @Published var isShowingCreateSheet = false
    
    // Form Properties
    @Published var selectedSubject: Subject?
    @Published var selectedBranch: KnowledgeBranch?
    @Published var selectedTopic: KnowledgeTopic?
    @Published var selectedStudyType: StudyType?
    @Published var missionHours: Int = 0
    @Published var missionMinutes: Int = 30
    @Published var isPomodoroEnabled: Bool = false
    
    var availableStudyTypes: [StudyType] {
        guard let category = selectedSubject?.category else { return [] }
        return StudyType.allCases.filter { $0.categories.contains(category) }
    }
    
    var knowledgeTree: [Subject] = []
    var dailyMissionSettings = DailyMissionSettings.default
    
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
    
    // MARK: - Mission Creation & Lifecycle
    
    /// Creates a standard mission from the user's form input.
    func createMission() {
        guard let subject = selectedSubject, let branch = selectedBranch, let topic = selectedTopic, let studyType = selectedStudyType else { return }
        
        let totalDuration = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        let initialTimeRemaining = isPomodoroEnabled ? pomodoroStudyDuration : totalDuration
        
        let newMission = Mission(id: UUID(), subjectName: subject.name, branchName: branch.name, topicName: topic.name, studyType: studyType, creationDate: Date(), totalDuration: totalDuration, timeRemaining: initialTimeRemaining, status: .pending, isPomodoro: isPomodoroEnabled, xpReward: (totalDuration / 60) * 2.5, goldReward: Int((totalDuration / 60) * 0.5))
        
        activeMissions.append(newMission)
        isShowingCreateSheet = false
        resetForm()
    }
    
    /// Creates a new mission from a Dungeon Stage template.
    func createMission(from stage: DungeonStage, in dungeon: Dungeon) {
        let topicName = "Dungeon: \(stage.name)"
        let duration = stage.requiredDuration
        let xpReward = (duration / 60) * 2.5
        let goldReward = Int((duration / 60) * 0.5)

        let newMission = Mission(id: UUID(), subjectName: dungeon.subjectName, branchName: dungeon.name, topicName: topicName, studyType: stage.studyType, creationDate: Date(), totalDuration: duration, timeRemaining: duration, status: .pending, xpReward: xpReward, goldReward: goldReward)
        
        activeMissions.append(newMission)
    }
    
    func startMission(mission: Mission) {
        guard let index = activeMissions.firstIndex(where: { $0.id == mission.id }) else { return }
        stopAllMissions()
        
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
        activeMissions[index].status = .paused
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
    
    func resetForm() {
        selectedSubject = nil; selectedBranch = nil; selectedTopic = nil; selectedStudyType = nil; missionHours = 0; missionMinutes = 30; isPomodoroEnabled = false
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
            completeMission(mission: activeMissions[activeIndex])
        }
    }
}

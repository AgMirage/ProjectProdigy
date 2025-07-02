import Foundation
import SwiftUI

/// Represents the current state of a mission.
enum MissionStatus: String, Codable, CaseIterable {
    case pending = "Pending", scheduled = "Scheduled", inProgress = "In Progress", paused = "Paused", completed = "Completed", failed = "Failed"
}

/// Tracks where a mission was generated. Crucial for filtering.
enum MissionSource: String, Codable {
    case manual, automatic, guild, dungeon
}

/// Represents the calculated difficulty of a mission.
enum MissionDifficulty: String, Codable {
    case easy, medium, hard, expert
}

/// Defines the different types of Boss Battles a player can schedule.
enum BossBattleType: String, Codable, CaseIterable, Identifiable {
    case finalExam = "Final Exam"
    case thesisDefense = "Thesis Defense"
    case projectShowcase = "Project Showcase"
    
    var id: Self { self }
}


/// Defines the different types of study activities a user can perform.
enum StudyType: String, Codable, CaseIterable {
    // General
    case reading, doingHomework, listeningToLecture, reviewingNotes, watchingVideo, doingSpeech, researching
    // STEM
    case solvingProblemSet, codingPractice, derivations, labSimulation, designingExperiment
    // Language
    case vocabularyPractice, speakingPractice, listeningComprehension, writingPractice
    // Humanities/Social Science
    case analyzingSources, writingEssay
    // Science-specific
    case memorizing
    // Special Event
    case majorEvent

    var displayString: String { self.rawValue.fromCamelCaseToSpacedTitle() }

    var categories: [SubjectCategory] {
        switch self {
        case .reading, .doingHomework, .listeningToLecture, .reviewingNotes, .watchingVideo, .doingSpeech, .researching, .majorEvent:
            return [.stem, .humanities, .language, .socialScience]
        case .solvingProblemSet, .codingPractice, .derivations, .labSimulation, .designingExperiment, .memorizing:
            return [.stem]
        case .vocabularyPractice, .speakingPractice, .listeningComprehension, .writingPractice:
            return [.language]
        case .analyzingSources, .writingEssay:
            return [.humanities, .socialScience]
        }
    }

    var iconName: String {
        switch self {
        case .reading, .reviewingNotes, .analyzingSources: return "book.fill"
        case .doingHomework, .solvingProblemSet, .derivations: return "pencil.and.ruler.fill"
        case .listeningToLecture, .listeningComprehension: return "ear.fill"
        case .watchingVideo: return "play.tv.fill"
        case .codingPractice: return "chevron.left.forward.slash.chevron.right"
        case .labSimulation, .designingExperiment: return "testtube.2"
        case .writingEssay, .researching, .writingPractice: return "doc.text.fill"
        case .doingSpeech: return "person.wave.2.fill"
        case .vocabularyPractice: return "text.book.closed.fill"
        case .speakingPractice: return "mouth.fill"
        case .memorizing: return "brain.fill"
        case .majorEvent: return "crown.fill"
        }
    }
}


/// Represents a single study task created by the user.
class Mission: ObservableObject, Identifiable, Codable, Hashable {
    let id: UUID
    let subjectName: String
    let branchName: String
    var topicName: String
    var studyType: StudyType
    let creationDate: Date
    var totalDuration: TimeInterval
    var isPomodoro: Bool
    let isBossBattle: Bool
    let goldWager: Int?
    var xpReward: Double
    var goldReward: Int
    
    @Published var scheduledDate: Date?
    @Published var timeRemaining: TimeInterval
    @Published var status: MissionStatus
    @Published var pomodoroCycle: Int
    @Published var isBreakTime: Bool
    @Published var source: MissionSource
    @Published var isPinned: Bool
    @Published var difficulty: MissionDifficulty
    @Published var allowedPauseTime: TimeInterval?
    @Published var timePaused: TimeInterval
    @Published var battleType: BossBattleType?
    
    @Published var isEligibleForCycleBonus: Bool
    @Published var isFinishingForBonus: Bool
    
    @Published var focusRating: Int?
    @Published var understandingRating: Int?
    @Published var challengeText: String?
    
    @Published var pomodoroStudyDuration: TimeInterval?
    @Published var pomodoroBreakDuration: TimeInterval?
    @Published var actualTimeSpent: TimeInterval?
    
    // --- NEW: Property to store the completion date ---
    @Published var completionDate: Date?


    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Conformance to Equatable
    static func == (lhs: Mission, rhs: Mission) -> Bool {
        lhs.id == rhs.id
    }
    
    // Manual implementation of Codable
    enum CodingKeys: String, CodingKey {
        case id, subjectName, branchName, topicName, studyType, creationDate, scheduledDate, totalDuration, timeRemaining, status, isPomodoro, pomodoroCycle, isBreakTime, isBossBattle, goldWager, xpReward, goldReward, source, isPinned, difficulty, allowedPauseTime, timePaused, battleType, isEligibleForCycleBonus, isFinishingForBonus, focusRating, understandingRating, challengeText, pomodoroStudyDuration, pomodoroBreakDuration, actualTimeSpent, completionDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        subjectName = try container.decode(String.self, forKey: .subjectName)
        branchName = try container.decode(String.self, forKey: .branchName)
        topicName = try container.decode(String.self, forKey: .topicName)
        studyType = try container.decode(StudyType.self, forKey: .studyType)
        creationDate = try container.decode(Date.self, forKey: .creationDate)
        scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        totalDuration = try container.decode(TimeInterval.self, forKey: .totalDuration)
        timeRemaining = try container.decode(TimeInterval.self, forKey: .timeRemaining)
        status = try container.decode(MissionStatus.self, forKey: .status)
        isPomodoro = try container.decode(Bool.self, forKey: .isPomodoro)
        pomodoroCycle = try container.decode(Int.self, forKey: .pomodoroCycle)
        isBreakTime = try container.decode(Bool.self, forKey: .isBreakTime)
        isBossBattle = try container.decode(Bool.self, forKey: .isBossBattle)
        goldWager = try container.decodeIfPresent(Int.self, forKey: .goldWager)
        xpReward = try container.decode(Double.self, forKey: .xpReward)
        goldReward = try container.decode(Int.self, forKey: .goldReward)
        source = try container.decode(MissionSource.self, forKey: .source)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        difficulty = try container.decode(MissionDifficulty.self, forKey: .difficulty)
        allowedPauseTime = try container.decodeIfPresent(TimeInterval.self, forKey: .allowedPauseTime)
        timePaused = try container.decode(TimeInterval.self, forKey: .timePaused)
        battleType = try container.decodeIfPresent(BossBattleType.self, forKey: .battleType)
        
        isEligibleForCycleBonus = try container.decodeIfPresent(Bool.self, forKey: .isEligibleForCycleBonus) ?? false
        isFinishingForBonus = try container.decodeIfPresent(Bool.self, forKey: .isFinishingForBonus) ?? false
        
        focusRating = try container.decodeIfPresent(Int.self, forKey: .focusRating)
        understandingRating = try container.decodeIfPresent(Int.self, forKey: .understandingRating)
        challengeText = try container.decodeIfPresent(String.self, forKey: .challengeText)
        
        pomodoroStudyDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .pomodoroStudyDuration)
        pomodoroBreakDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .pomodoroBreakDuration)
        actualTimeSpent = try container.decodeIfPresent(TimeInterval.self, forKey: .actualTimeSpent)
        
        completionDate = try container.decodeIfPresent(Date.self, forKey: .completionDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(subjectName, forKey: .subjectName)
        try container.encode(branchName, forKey: .branchName)
        try container.encode(topicName, forKey: .topicName)
        try container.encode(studyType, forKey: .studyType)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try container.encode(totalDuration, forKey: .totalDuration)
        try container.encode(timeRemaining, forKey: .timeRemaining)
        try container.encode(status, forKey: .status)
        try container.encode(isPomodoro, forKey: .isPomodoro)
        try container.encode(pomodoroCycle, forKey: .pomodoroCycle)
        try container.encode(isBreakTime, forKey: .isBreakTime)
        try container.encode(isBossBattle, forKey: .isBossBattle)
        try container.encodeIfPresent(goldWager, forKey: .goldWager)
        try container.encode(xpReward, forKey: .xpReward)
        try container.encode(goldReward, forKey: .goldReward)
        try container.encode(source, forKey: .source)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(allowedPauseTime, forKey: .allowedPauseTime)
        try container.encode(timePaused, forKey: .timePaused)
        try container.encodeIfPresent(battleType, forKey: .battleType)
        
        try container.encode(isEligibleForCycleBonus, forKey: .isEligibleForCycleBonus)
        try container.encode(isFinishingForBonus, forKey: .isFinishingForBonus)
        
        try container.encodeIfPresent(focusRating, forKey: .focusRating)
        try container.encodeIfPresent(understandingRating, forKey: .understandingRating)
        try container.encodeIfPresent(challengeText, forKey: .challengeText)
        
        try container.encodeIfPresent(pomodoroStudyDuration, forKey: .pomodoroStudyDuration)
        try container.encodeIfPresent(pomodoroBreakDuration, forKey: .pomodoroBreakDuration)
        try container.encodeIfPresent(actualTimeSpent, forKey: .actualTimeSpent)
        
        try container.encodeIfPresent(completionDate, forKey: .completionDate)
    }

    init(id: UUID, subjectName: String, branchName: String, topicName: String, studyType: StudyType, creationDate: Date, scheduledDate: Date? = nil, totalDuration: TimeInterval, timeRemaining: TimeInterval, status: MissionStatus, isPomodoro: Bool = false, pomodoroCycle: Int = 0, isBreakTime: Bool = false, isBossBattle: Bool = false, goldWager: Int? = nil, xpReward: Double, goldReward: Int, source: MissionSource = .manual, isPinned: Bool = false, difficulty: MissionDifficulty = .medium, allowedPauseTime: TimeInterval? = nil, timePaused: TimeInterval = 0, battleType: BossBattleType? = nil, isEligibleForCycleBonus: Bool = false, isFinishingForBonus: Bool = false, focusRating: Int? = nil, understandingRating: Int? = nil, challengeText: String? = nil, pomodoroStudyDuration: TimeInterval? = nil, pomodoroBreakDuration: TimeInterval? = nil, actualTimeSpent: TimeInterval? = nil, completionDate: Date? = nil) {
        self.id = id
        self.subjectName = subjectName
        self.branchName = branchName
        self.topicName = topicName
        self.studyType = studyType
        self.creationDate = creationDate
        self.scheduledDate = scheduledDate
        self.totalDuration = totalDuration
        self.timeRemaining = timeRemaining
        self.status = status
        self.isPomodoro = isPomodoro
        self.pomodoroCycle = pomodoroCycle
        self.isBreakTime = isBreakTime
        self.isBossBattle = isBossBattle
        self.goldWager = goldWager
        self.xpReward = xpReward
        self.goldReward = goldReward
        self.source = source
        self.isPinned = isPinned
        self.difficulty = difficulty
        self.allowedPauseTime = allowedPauseTime
        self.timePaused = timePaused
        self.battleType = battleType
        
        self.isEligibleForCycleBonus = isEligibleForCycleBonus
        self.isFinishingForBonus = isFinishingForBonus
        
        self.focusRating = focusRating
        self.understandingRating = understandingRating
        self.challengeText = challengeText
        
        self.pomodoroStudyDuration = pomodoroStudyDuration
        self.pomodoroBreakDuration = pomodoroBreakDuration
        self.actualTimeSpent = actualTimeSpent
        
        self.completionDate = completionDate
    }
    
    static var sample: Mission { Mission(id: UUID(), subjectName: "Mathematics", branchName: "Calculus 1", topicName: "The Chain Rule", studyType: .solvingProblemSet, creationDate: Date(), totalDuration: 3600, timeRemaining: 3600, status: .pending, xpReward: 150, goldReward: 25) }
    static var sample2: Mission { Mission(id: UUID(), subjectName: "Chemistry", branchName: "Organic Chemistry I", topicName: "Nomenclature", studyType: .reviewingNotes, creationDate: Date(), totalDuration: 1800, timeRemaining: 950, status: .inProgress, isPomodoro: true, pomodoroCycle: 1, isBreakTime: false, xpReward: 80, goldReward: 15) }
    static var sample3: Mission { Mission(id: UUID(), subjectName: "Physics", branchName: "Final Exams", topicName: "Thesis Defense", studyType: .majorEvent, creationDate: Date(), totalDuration: 0, timeRemaining: 0, status: .pending, isBossBattle: true, goldWager: 1000, xpReward: 5000, goldReward: 2000) }
}

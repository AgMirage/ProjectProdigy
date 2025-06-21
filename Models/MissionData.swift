import Foundation
import SwiftUI

/// Represents the current state of a mission.
enum MissionStatus: String, Codable, CaseIterable {
    case pending = "Pending", inProgress = "In Progress", paused = "Paused", completed = "Completed", failed = "Failed"
}

/// Tracks where a mission was generated. Crucial for filtering.
enum MissionSource: String, Codable {
    case manual, automatic, guild, dungeon
}

/// Represents the calculated difficulty of a mission.
enum MissionDifficulty: String, Codable {
    case easy, medium, hard, expert
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
        case .writingEssay, .researching: return "doc.text.fill"
        case .doingSpeech: return "person.wave.2.fill"
        case .vocabularyPractice: return "text.book.closed.fill"
        case .speakingPractice: return "mouth.fill"
        case .memorizing: return "brain.fill"
        case .majorEvent: return "crown.fill"
        // --- THIS LINE IS ADDED TO FIX THE ERROR ---
        case .writingPractice: return "square.and.pencil"
        }
    }
}


/// Represents a single study task created by the user.
struct Mission: Identifiable, Codable, Hashable {
    let id: UUID, subjectName: String, branchName: String, topicName: String
    let studyType: StudyType
    let creationDate: Date
    var scheduledDate: Date?
    var totalDuration: TimeInterval, timeRemaining: TimeInterval
    var status: MissionStatus
    var isPomodoro: Bool = false, pomodoroCycle: Int = 0, isBreakTime: Bool = false
    var isBossBattle: Bool = false, goldWager: Int?
    let xpReward: Double, goldReward: Int

    // --- NEW Properties to Add ---
    var source: MissionSource = .manual // To track where the mission came from.
    var isPinned: Bool = false // For prioritization.
    var difficulty: MissionDifficulty = .medium // For filtering and reward scaling.
    var allowedPauseTime: TimeInterval? // e.g., 10% of total Duration
    var timePaused: TimeInterval = 0 // To track pause time used.

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Mission, rhs: Mission) -> Bool { lhs.id == rhs.id }

    static var sample: Mission { Mission(id: UUID(), subjectName: "Mathematics", branchName: "Calculus 1", topicName: "The Chain Rule", studyType: .solvingProblemSet, creationDate: Date(), totalDuration: 3600, timeRemaining: 3600, status: .pending, xpReward: 150, goldReward: 25) }
    static var sample2: Mission { Mission(id: UUID(), subjectName: "Chemistry", branchName: "Organic Chemistry I", topicName: "Nomenclature", studyType: .reviewingNotes, creationDate: Date(), totalDuration: 1800, timeRemaining: 950, status: .inProgress, isPomodoro: true, pomodoroCycle: 1, isBreakTime: false, xpReward: 80, goldReward: 15) }
    static var sample3: Mission { Mission(id: UUID(), subjectName: "Physics", branchName: "Final Exams", topicName: "Thesis Defense", studyType: .majorEvent, creationDate: Date(), totalDuration: 0, timeRemaining: 0, status: .pending, isBossBattle: true, goldWager: 1000, xpReward: 5000, goldReward: 2000) }
}

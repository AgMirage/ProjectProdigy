import Foundation

/// Represents the days of the week for scheduling.
enum Weekday: Int, Codable, CaseIterable, Comparable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


/// A struct to hold all the user's preferences for their automatically generated daily missions.
struct DailyMissionSettings: Codable {
    /// A master switch to turn the entire feature on or off.
    var isEnabled: Bool
    
    /// The number of missions to generate per session.
    var missionCount: Int
    
    /// The duration for each generated mission (in seconds).
    var missionDuration: TimeInterval
    
    /// The specific days of the week the user has chosen to study on.
    var studyDays: Set<Weekday>
    
    /// An optional list of subject names to target. If nil, subjects are chosen randomly.
    var targetSubjectNames: [String]?
    
    /// The date when missions were last generated, to prevent creating duplicates in the same day.
    var lastGenerationDate: Date?
    
    // --- NEW: Customizable Pomodoro Durations ---
    /// The duration of a Pomodoro study cycle (in seconds).
    var pomodoroStudyDuration: TimeInterval
    
    /// The duration of a Pomodoro break cycle (in seconds).
    var pomodoroBreakDuration: TimeInterval
    
    /// Provides a default set of settings for a new user.
    static var `default`: DailyMissionSettings {
        DailyMissionSettings(
            isEnabled: false,
            missionCount: 2,
            missionDuration: 2700, // Default to 45 minutes
            studyDays: [.monday, .tuesday, .wednesday, .thursday, .friday], // Default to weekdays
            targetSubjectNames: nil,
            lastGenerationDate: nil,
            pomodoroStudyDuration: 25 * 60, // Default to 25 minutes
            pomodoroBreakDuration: 5 * 60  // Default to 5 minutes
        )
    }
}

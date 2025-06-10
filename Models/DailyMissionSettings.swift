import Foundation

/// Represents the days of the week for scheduling.
/// Codable allows it to be saved, and CaseIterable allows us to list all days easily in the UI.
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
    
    // Conformance to Comparable to allow sorting
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
    
    /// Provides a default set of settings for a new user.
    static var `default`: DailyMissionSettings {
        DailyMissionSettings(
            isEnabled: false,
            missionCount: 2,
            missionDuration: 2700, // Default to 45 minutes
            studyDays: [.monday, .tuesday, .wednesday, .thursday, .friday], // Default to weekdays
            targetSubjectNames: nil,
            lastGenerationDate: nil
        )
    }
}//
//  DailyMissionSettings.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


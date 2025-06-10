import Foundation

/// Defines a potential reward for completing an event's objectives.
struct EventReward: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String // e.g., "Exclusive 'Pi Day' Avatar" or "500 Gold"
    let iconName: String // e.g., "avatar_pi_day" or "icon_gold_coin"

    // This initializer fixes the Codable warning.
    init(id: UUID = UUID(), name: String, iconName: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
    }
}

/// Represents a single, time-sensitive in-game event.
struct Event: Identifiable, Codable, Hashable {
    let id: String // A unique key, e.g., "pi_day_2025"
    let name: String
    let description: String
    let bannerImageName: String

    let startDate: Date
    let endDate: Date

    let rewards: [EventReward]
}

/// A static data source for all planned events in the game.
struct EventCalendar {

    static let allEvents: [Event] = [
        Event(
            id: "pi_day_2025",
            name: "Pi Day Prodigy",
            description: "Celebrate the world's most famous mathematical constant! Complete a series of math-focused missions to earn exclusive rewards.",
            bannerImageName: "event_banner_pi_day",
            startDate: date(year: 2025, month: 3, day: 14),
            endDate: date(year: 2025, month: 3, day: 15),
            rewards: [
                EventReward(name: "'Pi Day' Avatar", iconName: "avatar_pi_day"),
                EventReward(name: "314 Gold", iconName: "icon_gold_coin")
            ]
        ),
        Event(
            id: "summer_study_2025",
            name: "Summer of Study",
            description: "Don't let the summer slide get you! Complete 50 missions over the summer to earn a special reward.",
            bannerImageName: "event_banner_summer",
            startDate: date(year: 2025, month: 6, day: 20),
            endDate: date(year: 2025, month: 8, day: 20),
            rewards: [
                EventReward(name: "'Summer Scholar' Frame", iconName: "frame_summer_scholar"),
                EventReward(name: "1000 Gold", iconName: "icon_gold_coin")
            ]
        ),
        Event(
            id: "avogadro_day_2025",
            name: "Mole Day Madness",
            description: "Celebrate Avogadro's number (6.022 x 10^23) with chemistry-themed challenges!",
            bannerImageName: "event_banner_chemistry",
            startDate: date(year: 2025, month: 10, day: 23),
            endDate: date(year: 2025, month: 10, day: 24),
            rewards: [
                EventReward(name: "'Master Chemist' Title", iconName: "icon_title_chemist"),
                EventReward(name: "602 Gold", iconName: "icon_gold_coin")
            ]
        ),
    ]

    /// A helper function to easily create dates.
    private static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 0
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }
}

//
//  EventManager.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import Foundation

class EventManager {
    
    /// A complete list of all events defined in the app's calendar.
    private let allEvents: [Event]
    
    init() {
        // When the manager is created, it loads all events from our static source.
        self.allEvents = EventCalendar.allEvents
    }
    
    /// A computed property that returns only the events that are currently active.
    var activeEvents: [Event] {
        let now = Date()
        // An event is active if the current date is between its start and end date.
        return allEvents.filter { event in
            event.startDate <= now && now < event.endDate
        }
    }
    
    /// A computed property that returns all upcoming events, sorted by their start date.
    var upcomingEvents: [Event] {
        let now = Date()
        // An event is upcoming if its start date is in the future.
        return allEvents
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate } // Sort to show the soonest event first.
    }
}
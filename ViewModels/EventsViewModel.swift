//
//  EventsViewModel.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import Foundation

@MainActor
class EventsViewModel: ObservableObject {
    
    /// The list of events currently active, ready for the UI to display.
    @Published var activeEvents: [Event] = []
    
    /// The list of upcoming events, ready for the UI to display.
    @Published var upcomingEvents: [Event] = []
    
    // The ViewModel holds an instance of the manager to get its data.
    private let eventManager: EventManager
    
    init() {
        self.eventManager = EventManager()
        // When the ViewModel is created, immediately load the event data.
        loadEvents()
    }
    
    /// Fetches the active and upcoming events from the EventManager.
    func loadEvents() {
        self.activeEvents = eventManager.activeEvents
        self.upcomingEvents = eventManager.upcomingEvents
    }
}
//
//  EventsView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import SwiftUI

struct EventsView: View {
    
    @StateObject private var viewModel = EventsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.activeEvents.isEmpty && viewModel.upcomingEvents.isEmpty {
                    // Show an empty state message if there are no events
                    VStack {
                        Spacer(minLength: 100)
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Events Scheduled")
                            .font(.title2)
                            .bold()
                        Text("Check back later for special events and challenges.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        // --- Active Events Section ---
                        if !viewModel.activeEvents.isEmpty {
                            Text("Active Events")
                                .font(.title2).bold()
                                .padding(.horizontal)
                            
                            ForEach(viewModel.activeEvents) { event in
                                EventCardView(event: event)
                            }
                        }
                        
                        // --- Upcoming Events Section ---
                        if !viewModel.upcomingEvents.isEmpty {
                            Text("Upcoming Events")
                                .font(.title2).bold()
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ForEach(viewModel.upcomingEvents) { event in
                                EventCardView(event: event)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Events")
            // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
            .background(Color.groupedBackground)
            .onAppear {
                // Refresh events each time the view appears
                viewModel.loadEvents()
            }
        }
    }
}

// MARK: - Helper View: EventCardView
struct EventCardView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(event.bannerImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(event.name)
                            .font(.headline)
                            .bold()
                        Text(formattedDateRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(timeStatus)
                        .font(.caption.bold())
                        .padding(8)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
                
                Text(event.description)
                    .font(.subheadline)
                
                Divider()
                
                Text("Rewards:")
                    .font(.caption.bold())
                
                HStack {
                    ForEach(event.rewards) { reward in
                        VStack {
                            Image(reward.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .padding(10)
                                .background(Color.gray.opacity(0.15))
                                .cornerRadius(8)
                            Text(reward.name)
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
            }
            .padding()
        }
        // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties for Date Formatting
    
    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
    }
    
    private var timeStatus: String {
        let now = Date()
        if now >= event.startDate && now < event.endDate {
            let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: event.endDate).day ?? 0
            return "Ends in \(daysRemaining + 1)d"
        } else if now < event.startDate {
            let daysUntil = Calendar.current.dateComponents([.day], from: now, to: event.startDate).day ?? 0
            return "Starts in \(daysUntil + 1)d"
        } else {
            return "Ended"
        }
    }
    
    private var statusColor: Color {
        let now = Date()
        if now >= event.startDate && now < event.endDate {
            return .green
        }
        return .orange
    }
}


// MARK: - Preview
struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView()
    }
}


// MARK: - Cross-Platform Color Helpers (NEW)
fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    static var secondaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}

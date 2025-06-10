//
//  AutomaticMissionsSettingsView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import SwiftUI

struct AutomaticMissionsSettingsView: View {
    
    // The view holds its own state for the settings.
    // In a real app, this would be loaded from and saved to persistent storage.
    @State private var settings = DailyMissionSettings.default
    
    // State to manage the hours and minutes for the duration picker
    @State private var missionHours: Int = 1
    @State private var missionMinutes: Int = 0

    var body: some View {
        Form {
            // Section 1: Master Toggle
            Section {
                Toggle("Enable Automatic Missions", isOn: $settings.isEnabled.animation())
            }
            
            // The rest of the form is disabled if the feature is turned off
            if settings.isEnabled {
                // Section 2: Mission Structure
                Section(header: Text("Mission Structure")) {
                    Stepper("Missions per Session: \(settings.missionCount)", value: $settings.missionCount, in: 1...5)
                    
                    VStack(alignment: .leading) {
                        Text("Duration per Mission")
                        HStack {
                            Spacer()
                            Picker("Hours", selection: $missionHours) {
                                ForEach(0..<5) { Text("\($0) hr").tag($0) }
                            }
                            // --- FIXED: '.wheel' is not available on macOS. Changed to '.menu'. ---
                            .pickerStyle(.menu)
                            
                            Picker("Minutes", selection: $missionMinutes) {
                                ForEach(0..<60) { Text("\($0) min").tag($0) }
                            }
                            // --- FIXED: '.wheel' is not available on macOS. Changed to '.menu'. ---
                            .pickerStyle(.menu)
                            Spacer()
                        }
                        .frame(height: 120)
                    }
                }
                
                // Section 3: Schedule
                Section(header: Text("Weekly Schedule")) {
                    WeekdaySelectorView(selectedDays: $settings.studyDays)
                }
            }
        }
        .navigationTitle("Daily Missions")
        .onAppear(perform: setupInitialState)
        .onDisappear(perform: saveSettings)
    }
    
    // MARK: - Helper Functions
    
    private func setupInitialState() {
        // When the view appears, break the saved TimeInterval into hours and minutes
        let duration = settings.missionDuration
        missionHours = Int(duration) / 3600
        missionMinutes = (Int(duration) % 3600) / 60
    }
    
    private func saveSettings() {
        // When the view disappears, combine hours and minutes back into a TimeInterval
        let durationInSeconds = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        settings.missionDuration = durationInSeconds
        
        // This is where you would save the 'settings' object to the device.
        print("Settings saved: \(settings)")
    }
}


// MARK: - Helper View: WeekdaySelector
struct WeekdaySelectorView: View {
    
    @Binding var selectedDays: Set<Weekday>
    private let allDays = Weekday.allCases.sorted()

    var body: some View {
        HStack {
            ForEach(allDays, id: \.self) { day in
                Text(day.shortName)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedDays.contains(day) ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                    .cornerRadius(8)
                    .onTapGesture {
                        toggleDay(day)
                    }
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}


// MARK: - Preview
struct AutomaticMissionsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AutomaticMissionsSettingsView()
        }
    }
}

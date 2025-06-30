import SwiftUI

// --- EDITED: Renamed view for clarity ---
struct TimerSettingsView: View {

    @Environment(\.dismiss) var dismiss

    @Binding var settings: DailyMissionSettings

    // --- EDITED: State for Pomodoro pickers ---
    @State private var pomodoroStudyMinutes: Int = 25
    @State private var pomodoroBreakMinutes: Int = 5
    
    @State private var missionHours: Int = 1
    @State private var missionMinutes: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Automatic Daily Missions")) {
                    Toggle("Enable Automatic Missions", isOn: $settings.isEnabled.animation())
                }

                if settings.isEnabled {
                    Section(header: Text("Automation Structure")) {
                        Stepper("Missions per Session: \(settings.missionCount)", value: $settings.missionCount, in: 1...5)
                        
                        LabeledContent("Duration per Mission") {
                            HStack {
                                Picker("Hours", selection: $missionHours) {
                                    ForEach(0..<5) { Text("\($0) hr").tag($0) }
                                }
                                .labelsHidden()

                                Picker("Minutes", selection: $missionMinutes) {
                                    ForEach(0..<60) { Text("\($0) min").tag($0) }
                                }
                                .labelsHidden()
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    Section(header: Text("Automation Schedule")) {
                        WeekdaySelectorView(selectedDays: $settings.studyDays)
                    }
                }
                
                // --- NEW: Section for Pomodoro Settings ---
                Section(header: Text("Pomodoro Timer Settings")) {
                    Stepper("Study Duration: \(pomodoroStudyMinutes) min", value: $pomodoroStudyMinutes, in: 5...90, step: 5)
                    
                    Stepper("Break Duration: \(pomodoroBreakMinutes) min", value: $pomodoroBreakMinutes, in: 1...30, step: 1)
                }
            }
            .navigationTitle("Automation & Timers")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear(perform: setupInitialState)
        .onChange(of: missionHours) { _, _ in syncMissionDuration() }
        .onChange(of: missionMinutes) { _, _ in syncMissionDuration() }
        // --- NEW: Sync changes from the new steppers ---
        .onChange(of: pomodoroStudyMinutes) { _, _ in syncPomodoroDurations() }
        .onChange(of: pomodoroBreakMinutes) { _, _ in syncPomodoroDurations() }
    }

    private func setupInitialState() {
        // For automatic missions
        let duration = settings.missionDuration
        missionHours = Int(duration) / 3600
        missionMinutes = (Int(duration) % 3600) / 60
        
        // For pomodoro
        pomodoroStudyMinutes = Int(settings.pomodoroStudyDuration) / 60
        pomodoroBreakMinutes = Int(settings.pomodoroBreakDuration) / 60
    }

    private func syncMissionDuration() {
        let durationInSeconds = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        settings.missionDuration = durationInSeconds
    }
    
    // --- NEW: Function to save Pomodoro settings ---
    private func syncPomodoroDurations() {
        settings.pomodoroStudyDuration = TimeInterval(pomodoroStudyMinutes * 60)
        settings.pomodoroBreakDuration = TimeInterval(pomodoroBreakMinutes * 60)
    }
}

// MARK: - Helper Views (Unchanged)
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

struct TimerSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TimerSettingsView(settings: .constant(.default))
    }
}

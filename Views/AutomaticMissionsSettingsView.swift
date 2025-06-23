import SwiftUI

struct AutomaticMissionsSettingsView: View {

    @Environment(\.dismiss) var dismiss

    @Binding var settings: DailyMissionSettings

    @State private var missionHours: Int = 1
    @State private var missionMinutes: Int = 0

    var body: some View {
        // --- EDITED: Added a NavigationStack for a clean title and Done button ---
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable Automatic Missions", isOn: $settings.isEnabled.animation())
                }

                if settings.isEnabled {
                    Section(header: Text("Mission Structure")) {
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

                    Section(header: Text("Weekly Schedule")) {
                        WeekdaySelectorView(selectedDays: $settings.studyDays)
                    }
                }
            }
            .navigationTitle("Automatic Missions")
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
    }

    private func setupInitialState() {
        let duration = settings.missionDuration
        missionHours = Int(duration) / 3600
        missionMinutes = (Int(duration) % 3600) / 60
    }

    private func syncMissionDuration() {
        let durationInSeconds = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
        settings.missionDuration = durationInSeconds
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

struct AutomaticMissionsSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AutomaticMissionsSettingsView(settings: .constant(.default))
    }
}

import SwiftUI

struct ArchivedMissionDetailView: View {
    let mission: Mission

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Section 1: Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mission Summary")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        InfoRow(label: "Topic", value: mission.topicName)
                        InfoRow(label: "Subject", value: mission.subjectName)
                        InfoRow(label: "Branch", value: mission.branchName)
                        InfoRow(label: "Study Type", value: mission.studyType.displayString)
                        // --- NEW: Displays the completion date ---
                        if let completionDate = mission.completionDate {
                            InfoRow(label: "Completed On", value: completionDate.formatted(date: .abbreviated, time: .shortened))
                        }
                        InfoRow(label: "Status", value: mission.status.rawValue, statusColor: statusColor)
                    }
                    .padding()
                    .background(Color.secondaryBackground)
                    .cornerRadius(12)
                }

                // Section 2: Time & Rewards
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time & Rewards")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        InfoRow(label: "Planned Duration", value: format(duration: mission.totalDuration))
                        InfoRow(label: "Time Spent", value: format(duration: mission.actualTimeSpent ?? 0))
                        InfoRow(label: "XP Earned", value: "\(Int(mission.xpReward))")
                        InfoRow(label: "Gold Earned", value: "\(mission.goldReward)")
                    }
                    .padding()
                    .background(Color.secondaryBackground)
                    .cornerRadius(12)
                }
                
                // Section 3: Pomodoro Details
                if mission.isPomodoro, let studyDuration = mission.pomodoroStudyDuration, let breakDuration = mission.pomodoroBreakDuration {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timer Settings")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            InfoRow(label: "Mode", value: "Pomodoro")
                            InfoRow(label: "Focus Cycle", value: format(duration: studyDuration))
                            InfoRow(label: "Break Cycle", value: format(duration: breakDuration))
                        }
                        .padding()
                        .background(Color.secondaryBackground)
                        .cornerRadius(12)
                    }
                }
                
                // Section 4: Review
                if let focusRating = mission.focusRating, let understandingRating = mission.understandingRating {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Review")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 12) {
                            StarRatingRow(label: "Focus Rating", rating: focusRating)
                            StarRatingRow(label: "Understanding", rating: understandingRating)

                            if let challengeText = mission.challengeText, !challengeText.isEmpty {
                                Divider()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Biggest Challenge:")
                                        .font(.headline)
                                    Text(challengeText)
                                        .font(.body)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondaryBackground)
                        .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.groupedBackground)
        .navigationTitle("Mission Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    /// Formats a time interval into a readable string like "1h 30m".
    private func format(duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }

    private var statusColor: Color {
        switch mission.status {
        case .completed: return .green
        case .failed: return .red
        default: return .gray
        }
    }
}

// Helper views for the detail screen
struct InfoRow: View {
    let label: String
    let value: String
    var statusColor: Color? = nil

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(statusColor ?? .secondary)
                .bold(statusColor != nil)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct StarRatingRow: View {
    let label: String
    let rating: Int

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Image(systemName: i <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}


struct ArchiveView: View {

    let archivedMissions: [Mission]

    var body: some View {
        NavigationStack {
            if archivedMissions.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Archived Missions")
                        .font(.title2)
                        .bold()
                    Text("Completed or failed missions will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .navigationTitle("Mission Archive")
            } else {
                List(archivedMissions) { mission in
                    NavigationLink(destination: ArchivedMissionDetailView(mission: mission)) {
                        ArchivedMissionRowView(mission: mission)
                    }
                }
                .navigationTitle("Mission Archive")
            }
        }
    }
}

// MARK: - Helper View: ArchivedMissionRowView
struct ArchivedMissionRowView: View {
    let mission: Mission

    private var statusColor: Color {
        switch mission.status {
        case .completed: return .green
        case .failed: return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mission.topicName)
                    .font(.headline)
                    .strikethrough(mission.status == .completed)

                Text("\(mission.subjectName) / \(mission.branchName)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Text("Status: \(mission.status.rawValue)")
                        .font(.caption)
                        .bold()
                        .foregroundColor(statusColor)

                    if mission.focusRating != nil {
                        Image(systemName: "pencil.and.outline")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("+\(Int(mission.xpReward)) XP")
                Text("+\(mission.goldReward) Gold")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .opacity(mission.status == .completed ? 1.0 : 0.5)
        }
        .padding(.vertical, 8)
    }
}


// MARK: - Preview
struct ArchiveView_Previews: PreviewProvider {
    static var previews: some View {
        let completedMission = Mission.sample
        completedMission.status = .completed
        completedMission.focusRating = 4
        completedMission.understandingRating = 5
        completedMission.challengeText = "The final integration was tricky."
        completedMission.isPomodoro = true
        completedMission.pomodoroStudyDuration = 1500
        completedMission.pomodoroBreakDuration = 300
        completedMission.actualTimeSpent = 3000
        completedMission.completionDate = Date().addingTimeInterval(-86400) // Yesterday

        let failedMission = Mission.sample2
        failedMission.status = .failed

        return ArchiveView(archivedMissions: [completedMission, failedMission])
    }
}

// MARK: - Cross-Platform Color Helpers
fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    static var secondaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}

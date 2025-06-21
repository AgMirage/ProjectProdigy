//
//  ArchiveView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/21/25.
//


import SwiftUI

struct ArchiveView: View {
    
    // The view takes the list of archived missions as an input.
    let archivedMissions: [Mission]
    
    var body: some View {
        NavigationStack {
            // Check if the archive is empty.
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
                // If there are missions, display them in a list.
                List(archivedMissions) { mission in
                    ArchivedMissionRowView(mission: mission)
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
                
                Text("Status: \(mission.status.rawValue)")
                    .font(.caption)
                    .bold()
                    .foregroundColor(statusColor)
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
        // Create some sample data for the preview.
        var completedMission = Mission.sample
        completedMission.status = .completed
        
        var failedMission = Mission.sample2
        failedMission.status = .failed
        
        return ArchiveView(archivedMissions: [completedMission, failedMission])
    }
}

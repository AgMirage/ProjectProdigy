//
//  GuildView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import SwiftUI

struct GuildView: View {
    
    @StateObject private var viewModel: GuildViewModel
    
    init(mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: GuildViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        NavigationStack {
            if let guild = viewModel.guild {
                ScrollView {
                    VStack(spacing: 20) {
                        GuildMissionView(mission: guild.activeMission)
                        GuildRosterView(members: guild.members)
                    }
                    .padding()
                }
                .navigationTitle(guild.name)
                // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
                .background(Color.groupedBackground)
            } else {
                // Loading or error state
                Text("Loading Guild Hall...")
            }
        }
    }
}

// MARK: - Helper View: GuildMissionView
struct GuildMissionView: View {
    let mission: GuildMission
    
    private var progress: Double {
        return mission.currentProgress / mission.goal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Guild Mission")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(mission.title)
                .font(.title2.bold())
            
            ProgressView(value: progress) {
                HStack {
                    Text("Progress")
                    Spacer()
                    Text("\(Int(progress * 100))%")
                }
            }
            .tint(.cyan)
            
            Text(mission.description)
                .font(.footnote)
                .padding(.bottom, 5)
            
            Divider()
            
            HStack {
                Text("Reward:")
                    .font(.caption.bold())
                Spacer()
                Image(mission.rewardIconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                Text(mission.rewardDescription)
                    .font(.subheadline)
            }
        }
        .padding()
        // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
        .background(Color.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Helper View: GuildRosterView
struct GuildRosterView: View {
    let members: [GuildMember]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Members")
                .font(.title2.bold())
                .padding(.horizontal)
            
            VStack(spacing: 2) {
                ForEach(members) { member in
                    GuildMemberRowView(member: member)
                }
            }
            // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
            .background(Color.secondaryBackground)
            .cornerRadius(12)
        }
    }
}


// MARK: - Helper View: GuildMemberRowView
struct GuildMemberRowView: View {
    let member: GuildMember
    
    var body: some View {
        HStack {
            Image(member.avatarName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            
            Text(member.username)
                .font(.headline)
            
            if member.isActive {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            
            Spacer()
            
            Text("Lvl: \(member.level)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        // Highlight the real player's row
        .background(member.isActive ? Color.blue.opacity(0.1) : Color.clear)
    }
}


// MARK: - Preview
struct GuildView_Previews: PreviewProvider {
    static var previews: some View {
        let mainVM = MainViewModel(player: Player(username: "PreviewUser"))
        GuildView(mainViewModel: mainVM)
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

//
//  GuildViewModel.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import Foundation

@MainActor
class GuildViewModel: ObservableObject {
    
    /// The player's current guild. It's optional in case the data fails to load.
    @Published var guild: Guild?
    
    private weak var mainViewModel: MainViewModel?
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.loadGuildData()
    }
    
    /// Generates the simulated guild data using the factory.
    private func loadGuildData() {
        guard let player = mainViewModel?.player else { return }
        self.guild = FakeGuildFactory.createPlayerGuild(for: player)
    }
    
    /// This function would be called when a player completes a mission
    /// that qualifies for the weekly guild goal.
    func handleMissionContribution(mission: Mission) {
        // For our sample "STEM Study Blitz", we check if the mission subject is STEM.
        let stemSubjects = ["Mathematics", "Chemistry", "Physics", "Computer Science"]
        guard let guild = self.guild,
              guild.activeMission.id == "guild_mission_stem_hours_1",
              stemSubjects.contains(mission.subjectName)
        else {
            return
        }

        // Add the duration of the completed mission to the guild's progress.
        self.guild?.activeMission.currentProgress += mission.totalDuration
        
        mainViewModel?.addLogEntry(
            "Your work contributed to the guild mission!",
            color: .cyan
        )
    }
}
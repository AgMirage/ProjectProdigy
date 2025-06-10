import Foundation

/// Represents a single member within a study guild.
struct GuildMember: Identifiable, Codable, Hashable {
    let id: UUID
    var username: String
    var avatarName: String
    var level: Int
    var isActive: Bool // Is this the real player?
    
    init(id: UUID = UUID(), username: String, avatarName: String, level: Int, isActive: Bool = false) {
        self.id = id
        self.username = username
        self.avatarName = avatarName
        self.level = level
        self.isActive = isActive
    }
}

/// Represents the weekly collective mission for the guild.
struct GuildMission: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String
    var goal: Double
    var currentProgress: Double
    var rewardDescription: String
    var rewardIconName: String
}

/// Represents a single Study Guild/Club.
struct Guild: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var iconName: String
    var members: [GuildMember]
    var activeMission: GuildMission
    
    init(id: UUID = UUID(), name: String, iconName: String, members: [GuildMember], activeMission: GuildMission) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.members = members
        self.activeMission = activeMission
    }
}


/// A static factory to generate a simulated guild for the player.
struct FakeGuildFactory {
    
    /// Creates the default guild that the player will be a part of.
    /// - Parameter player: The real player object to insert into the member list.
    /// - Returns: A fully formed Guild object.
    static func createPlayerGuild(for player: Player) -> Guild {
        // Create the real player's member entry
        let playerMember = GuildMember(id: player.id, username: player.username, avatarName: player.currentAvatar.imageName, level: player.academicTier.level, isActive: true)
        
        // Create a few fake members
        let fakeMember1 = GuildMember(username: "Scribe", avatarName: "avatar_f_generic_02", level: 12)
        let fakeMember2 = GuildMember(username: "Cogitator", avatarName: "avatar_m_generic_01", level: 15)
        let fakeMember3 = GuildMember(username: "Nexus", avatarName: "avatar_scholar_gacha", level: 18)
        
        var allMembers = [playerMember, fakeMember1, fakeMember2, fakeMember3]
        // Sort members by level, descending.
        allMembers.sort { $0.level > $1.level }
        
        // Create the weekly guild mission
        let weeklyMission = GuildMission(
            id: "guild_mission_stem_hours_1",
            title: "STEM Study Blitz",
            description: "As a guild, complete a total of 25 hours of study in any STEM subjects (Math, Chemistry, Physics, CompSci).",
            goal: 90000, // 25 hours in seconds
            currentProgress: 15000, // Start with some progress from the fake members
            rewardDescription: "Rare Consumable Pack",
            rewardIconName: "icon_reward_pack"
        )
        
        // Assemble the final guild
        return Guild(
            name: "The Erudite Collective",
            iconName: "icon_guild_erudite",
            members: allMembers,
            activeMission: weeklyMission
        )
    }
}//
//  GuildData.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


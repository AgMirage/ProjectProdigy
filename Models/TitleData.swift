import Foundation

/// Represents a single, displayable title that a player can earn.
struct Title: Identifiable, Codable, Hashable {
    /// A unique string key for this title (e.g., "calculus_conqueror").
    let id: String
    let name: String
    let description: String
}


/// A static data source for all Titles available in the game.
struct TitleList {
    
    static let allTitles: [Title] = [
        // Achievement-based Titles
        Title(
            id: "emergent_expert",
            name: "Emergent Expert",
            description: "Awarded for reaching Character Level 10."
        ),
        Title(
            id: "weekly_warrior",
            name: "Weekly Warrior",
            description: "Awarded for maintaining a 7-day check-in streak."
        ),
        
        // Dungeon-based Titles
        Title(
            id: "thesis_champion",
            name: "Thesis Champion",
            description: "Awarded for successfully completing the Chemistry Term Paper dungeon."
        ),
        
        // Knowledge-based Titles
        Title(
            id: "calculus_conqueror",
            name: "Calculus Conqueror",
            description: "Awarded for mastering all high school and college Calculus branches."
        ),
        Title(
            id: "organic_virtuoso",
            name: "Organic Virtuoso",
            description: "Awarded for mastering Organic Chemistry I & II."
        )
    ]
    
    /// A helper function to easily find a title by its ID.
    static func byId(_ id: String) -> Title? {
        return allTitles.first { $0.id == id }
    }
}//
//  TitleData.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import Foundation

/// Represents a single step or stage within a Dungeon.
struct DungeonStage: Identifiable, Codable, Hashable {
    let id: UUID
    let stageNumber: Int
    let name: String
    let description: String
    let studyType: StudyType
    let requiredDuration: TimeInterval // The suggested duration for this stage's mission
    
    init(id: UUID = UUID(), stageNumber: Int, name: String, description: String, studyType: StudyType, requiredDuration: TimeInterval) {
        self.id = id
        self.stageNumber = stageNumber
        self.name = name
        self.description = description
        self.studyType = studyType
        self.requiredDuration = requiredDuration
    }
}

/// Defines the bonus reward for completing an entire Dungeon.
struct DungeonReward: Codable, Hashable {
    let gold: Int
    let xp: Double
    let title: String? // Optional new title reward
}

/// Represents a pre-defined chain of missions (a "Dungeon") designed to simulate a large academic project.
struct Dungeon: Identifiable, Codable, Hashable {
    let id: String // e.g. "chem_term_paper"
    let name: String
    let description: String
    let subjectName: String
    let iconName: String
    let stages: [DungeonStage]
    let finalReward: DungeonReward
}

/// Tracks an individual player's progress through a Dungeon.
struct PlayerDungeonStatus: Identifiable, Codable, Hashable {
    var id: String { dungeonID } // The dungeon's ID is the status's ID
    let dungeonID: String
    var currentStage: Int // The stage number the player is currently on
    var isCompleted: Bool
}


/// A static data source for all Dungeons available in the game.
struct DungeonList {
    static let allDungeons: [Dungeon] = [
        Dungeon(
            id: "chem_term_paper",
            name: "Term Paper (Chemistry)",
            description: "A multi-stage project to research, draft, and finalize a term paper on a chemistry topic.",
            subjectName: "Chemistry",
            iconName: "icon_dungeon_paper",
            stages: [
                DungeonStage(stageNumber: 1, name: "Research Phase", description: "Gather and read relevant research papers and articles.", studyType: .researching, requiredDuration: 7200), // 2 hrs
                DungeonStage(stageNumber: 2, name: "Outline & Structure", description: "Create a detailed outline for the paper.", studyType: .writingEssay, requiredDuration: 3600), // 1 hr
                DungeonStage(stageNumber: 3, name: "Draft Writing", description: "Write the first full draft of the term paper.", studyType: .writingEssay, requiredDuration: 14400), // 4 hrs
                DungeonStage(stageNumber: 4, name: "Revision & Editing", description: "Revise the draft for clarity, accuracy, and style.", studyType: .reviewingNotes, requiredDuration: 7200) // 2 hrs
            ],
            finalReward: DungeonReward(gold: 2500, xp: 5000, title: "Thesis Champion")
        ),
        Dungeon(
            id: "math_midterm_prep",
            name: "Midterm Prep (Applied Math)",
            description: "A rigorous study plan to prepare for a comprehensive midterm exam in Applied Mathematics.",
            subjectName: "Mathematics",
            iconName: "icon_dungeon_exam",
            stages: [
                DungeonStage(stageNumber: 1, name: "Concept Review", description: "Thoroughly review all lecture notes and relevant textbook chapters.", studyType: .reviewingNotes, requiredDuration: 5400), // 1.5 hrs
                DungeonStage(stageNumber: 2, name: "Problem Set Gauntlet A", description: "Complete the first half of the practice problem set.", studyType: .solvingProblemSet, requiredDuration: 7200), // 2 hrs
                DungeonStage(stageNumber: 3, name: "Problem Set Gauntlet B", description: "Complete the second half of the practice problem set.", studyType: .solvingProblemSet, requiredDuration: 7200), // 2 hrs
                DungeonStage(stageNumber: 4, name: "Mock Exam Simulation", description: "Take a practice exam under timed conditions to test your knowledge.", studyType: .solvingProblemSet, requiredDuration: 10800) // 3 hrs
            ],
            finalReward: DungeonReward(gold: 3000, xp: 4000, title: nil)
        )
    ]
}//
//  DungeonData.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


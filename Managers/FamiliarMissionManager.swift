//
//  FamiliarMissionManager.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 8/19/25.
//


//
//  FamiliarMissionManager.swift
//  ProjectProdigy
//
//  Created by Gemini on 8/19/25.
//

import Foundation

class FamiliarMissionManager {
    
    /// Generates a new mission for the active familiar.
    /// - Parameter familiar: The player's active familiar.
    /// - Returns: A new `Mission` object, or `nil` if a mission cannot be generated.
    func generateMission(for familiar: Familiar) -> Mission? {
        // For simplicity, we'll create a single type of mission.
        // In a real game, this could be expanded with different mission types based on familiar, level, etc.
        let mission = Mission(
            id: UUID(),
            subjectName: "Familiar",
            branchName: familiar.name,
            topicName: "Interact with \(familiar.name)",
            studyType: .familiarInteraction,
            creationDate: Date(),
            totalDuration: 600, // 10 minutes
            timeRemaining: 600,
            status: .pending,
            xpReward: 50,
            goldReward: 10,
            source: .familiar
        )
        return mission
    }
}
//
//  DailyMissionManager.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


import Foundation

class DailyMissionManager {
    
    // The manager holds a mutable copy of the user's settings.
    var settings: DailyMissionSettings
    
    init(settings: DailyMissionSettings) {
        self.settings = settings
    }
    
    /// Checks all conditions and, if met, generates a new list of missions for the day.
    /// - Parameter knowledgeTree: The player's full knowledge tree, used to select topics from.
    /// - Returns: An array of new `Mission` objects, or an empty array if conditions are not met.
    func generateMissionsForToday(knowledgeTree: [Subject]) -> [Mission] {
        // 1. Check if the feature is enabled.
        guard settings.isEnabled else {
            print("Daily Missions: Feature is disabled.")
            return []
        }
        
        // 2. Check if today is a scheduled study day.
        guard isStudyDay() else {
            print("Daily Missions: Today is not a scheduled study day.")
            return []
        }
        
        // 3. Check if we have already generated missions for today.
        guard !didGenerateToday() else {
            print("Daily Missions: Missions have already been generated for today.")
            return []
        }
        
        print("Daily Missions: Generating \(settings.missionCount) new missions for today...")
        
        var newMissions: [Mission] = []
        
        for _ in 0..<settings.missionCount {
            // Find a valid, unlocked topic to create a mission for.
            guard let randomTopicInfo = findRandomUnlockedTopic(in: knowledgeTree) else {
                print("Daily Missions Warning: Could not find an unlocked topic to generate a mission for.")
                continue // Skip this iteration if no topic can be found.
            }
            
            // Calculate rewards based on duration.
            let xpReward = (settings.missionDuration / 60) * 2.5 // 2.5 XP per minute
            let goldReward = Int((settings.missionDuration / 60) * 0.5) // 0.5 Gold per minute

            let mission = Mission(
                id: UUID(),
                subjectName: randomTopicInfo.subjectName,
                branchName: randomTopicInfo.branchName,
                topicName: randomTopicInfo.topic.name,
                studyType: .reviewingNotes, // Default to a general study type
                creationDate: Date(),
                totalDuration: settings.missionDuration,
                timeRemaining: settings.missionDuration,
                status: .pending,
                xpReward: xpReward,
                goldReward: goldReward
            )
            newMissions.append(mission)
        }
        
        // IMPORTANT: Update the last generation date to prevent re-generation today.
        self.settings.lastGenerationDate = Date()
        
        return newMissions
    }
    
    // MARK: - Helper Methods
    
    /// Finds a random, unlocked topic from the entire knowledge tree.
    private func findRandomUnlockedTopic(in tree: [Subject]) -> (topic: KnowledgeTopic, branchName: String, subjectName: String)? {
        // Get a list of all unlocked branches across all subjects.
        let allUnlockedBranches = tree.flatMap { subject in
            subject.branches
                .filter { $0.isUnlocked }
                .map { (branch: $0, subjectName: subject.name) } // Pair branch with its subject name
        }
        
        guard !allUnlockedBranches.isEmpty else { return nil }
        
        // Pick a random branch from the list of unlocked branches.
        let randomBranchInfo = allUnlockedBranches.randomElement()!
        
        // Find an unlocked topic within that branch.
        let unlockedTopics = randomBranchInfo.branch.topics.filter { $0.isUnlocked }
        
        guard let randomTopic = unlockedTopics.randomElement() else { return nil }
        
        return (topic: randomTopic, branchName: randomBranchInfo.branch.name, subjectName: randomBranchInfo.subjectName)
    }
    
    /// Checks if the current day of the week is in the user's study schedule.
    private func isStudyDay() -> Bool {
        let today = Calendar.current.component(.weekday, from: Date()) // Sunday = 1, Saturday = 7
        guard let currentWeekday = Weekday(rawValue: today) else { return false }
        
        return settings.studyDays.contains(currentWeekday)
    }
    
    /// Checks if the `lastGenerationDate` is today.
    private func didGenerateToday() -> Bool {
        guard let lastDate = settings.lastGenerationDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
}
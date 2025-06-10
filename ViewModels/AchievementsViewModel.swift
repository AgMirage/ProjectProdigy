import Foundation
import Combine

/// A data structure that combines a static `Achievement` with the player's dynamic `PlayerAchievementStatus`
/// into a single object, making it easy for the UI to display.
struct AchievementDisplayData: Identifiable {
    let id: String
    let name: String
    let description: String
    let tierImageName: String
    let goldReward: Int
    let goal: Double
    let isSecret: Bool
    
    // Player-specific data
    let progress: Double
    let isUnlocked: Bool
    let unlockedDate: Date?
}

/// Defines the filtering options for the achievements list.
enum AchievementFilter: String, CaseIterable {
    case all = "All"
    case inProgress = "In Progress"
    case unlocked = "Unlocked"
}

@MainActor
class AchievementsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The final list of achievements to be displayed, after processing and filtering.
    @Published var achievementsToDisplay: [AchievementDisplayData] = []
    
    /// The currently active filter for the list.
    @Published var selectedFilter: AchievementFilter = .all
    
    // The source of truth for achievement data.
    private var achievementManager: AchievementManager
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    
    init(manager: AchievementManager) {
        self.achievementManager = manager
        
        // Subscribe to changes in the AchievementManager's statuses.
        // Whenever an achievement is unlocked, this will automatically trigger a UI refresh.
        manager.$statuses
            .sink { [weak self] _ in
                self?.prepareDisplayData()
            }
            .store(in: &cancellables)
            
        // Also subscribe to changes in the local filter selection.
        $selectedFilter
            .sink { [weak self] _ in
                self?.prepareDisplayData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Logic
    
    /// This is the core function that processes the raw data from the manager
    /// into the display-ready format.
    private func prepareDisplayData() {
        let allAchievements = AchievementList.allAchievements
        var displayData: [AchievementDisplayData] = []

        for achievement in allAchievements {
            guard let status = achievementManager.statuses[achievement.id] else { continue }
            
            // Apply the current filter
            switch selectedFilter {
            case .all:
                break // No filtering, include all
            case .inProgress:
                if status.isUnlocked { continue } // Skip unlocked
            case .unlocked:
                if !status.isUnlocked { continue } // Skip locked
            }
            
            displayData.append(
                AchievementDisplayData(
                    id: achievement.id,
                    name: achievement.name,
                    description: achievement.description,
                    tierImageName: achievement.tier.imageName,
                    goldReward: achievement.goldReward,
                    goal: achievement.goal,
                    isSecret: achievement.isSecret,
                    progress: status.progress,
                    isUnlocked: status.isUnlocked,
                    unlockedDate: status.unlockedDate
                )
            )
        }
        
        // Sort the list so that in-progress items appear before unlocked items.
        self.achievementsToDisplay = displayData.sorted {
            if $0.isUnlocked != $1.isUnlocked {
                return !$0.isUnlocked && $1.isUnlocked // In-progress ($0) comes before unlocked ($1)
            }
            // If both have the same unlocked status, sort by name
            return $0.name < $1.name
        }
    }
}//
//  AchievementsViewModel.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/11/25.
//


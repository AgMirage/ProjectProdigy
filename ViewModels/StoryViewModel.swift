import Foundation

@MainActor
class StoryViewModel: ObservableObject {
    
    // The master list of all available stories.
    @Published var allStories: [Story] = []
    
    // A dictionary tracking the player's progress for each story.
    @Published var playerProgress: [String: PlayerStoryProgress] = [:]
    
    // For showing alerts like "Not enough Gold".
    @Published var alertItem: AlertItem?
    
    // This is no longer private, allowing the view to access it.
    weak var mainViewModel: MainViewModel?
    
    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        self.allStories = StoryList.allStories
        self.initializeProgress()
    }
    
    /// Checks if a specific section of a story has been unlocked by the player.
    func isSectionUnlocked(storyID: String, sectionNumber: Int) -> Bool {
        return playerProgress[storyID]?.unlockedSectionNumbers.contains(sectionNumber) ?? false
    }
    
    /// The main function to purchase and unlock a story section.
    func unlockSection(story: Story, section: StorySection) {
        guard let mainVM = mainViewModel else { return }
        
        // 1. Check if player has enough gold.
        guard mainVM.player.gold >= section.goldCost else {
            alertItem = AlertItem(title: "Not Enough Gold", message: "You need \(section.goldCost) Gold to unlock this part of the story.")
            return
        }
        
        // 2. Deduct gold.
        mainVM.player.gold -= section.goldCost
        
        // 3. Update the progress state.
        playerProgress[story.id]?.unlockedSectionNumbers.insert(section.sectionNumber)
        
        // 4. Log the event.
        mainVM.addLogEntry("Unlocked '\(section.title)' in the story: \(story.title)!", color: .purple)
        
        // Manually notify SwiftUI that our nested data has changed.
        objectWillChange.send()
    }
    
    /// Ensures there is a progress tracking object for every story.
    private func initializeProgress() {
        // In a real app, you would load playerProgress from a save file here.
        for story in allStories {
            if playerProgress[story.id] == nil {
                playerProgress[story.id] = PlayerStoryProgress(
                    storyID: story.id,
                    unlockedSectionNumbers: Set<Int>() // Start with no sections unlocked
                )
            }
        }
    }
}

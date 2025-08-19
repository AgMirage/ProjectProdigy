import Foundation

/// Represents one unlockable section or chapter of a story.
struct StorySection: Identifiable, Codable, Hashable {
    let id: UUID
    let sectionNumber: Int
    let title: String
    let content: String // The actual narrative text for the section.
    let goldCost: Int

    init(id: UUID = UUID(), sectionNumber: Int, title: String, content: String, goldCost: Int) {
        self.id = id
        self.sectionNumber = sectionNumber
        self.title = title
        self.content = content
        self.goldCost = goldCost
    }
}

/// Represents a complete story with all its chapters.
struct Story: Identifiable, Codable, Hashable {
    let id: String // e.g., "alchemist_manuscript"
    let title: String
    let description: String
    let bannerImageName: String
    let sections: [StorySection]
}

/// Tracks which sections of a story a player has unlocked.
struct PlayerStoryProgress: Codable, Hashable {
    let storyID: String
    var unlockedSectionNumbers: Set<Int>
}


/// A static "factory" that defines all stories available in the game.
struct StoryList {
    static let allStories: [Story] = [
        // --- NEW STORY ---
        Story(
            id: "prodigy_origin",
            title: "The Prodigy's Origin",
            description: "Discover the source of your unique abilities and the system that guides you.",
            bannerImageName: "story_banner_origin",
            sections: [
                StorySection(sectionNumber: 1, title: "The Anomaly", content: "It started subtly. A flicker in your vision, a sense of clarity you'd never known. You begin to realize you're not just studying... you're evolving.", goldCost: 0),
                StorySection(sectionNumber: 2, title: "First Contact", content: "A message appears in your mind, not in words, but in pure data. A mysterious benefactor offers you a choice: embrace your potential or return to a normal life.", goldCost: 50),
            ]
        ),
        // --- END NEW STORY ---
        Story(
            id: "alchemist_manuscript",
            title: "The Alchemist's Manuscript",
            description: "Uncover the secrets of a long-lost alchemical text. Each chapter reveals more of a forgotten history and the power of Chemistry.",
            bannerImageName: "story_banner_alchemy",
            sections: [
                StorySection(sectionNumber: 1, title: "The Discovery", content: "You find a dusty, locked chest in the corner of the university library's oldest section. A faint, chemical smell emanates from it...", goldCost: 100),
                StorySection(sectionNumber: 2, title: "The First Riddle", content: "Inside the chest is a single page written in code. It speaks of two elements, one that gives life and one that takes it, bound together...", goldCost: 250),
                StorySection(sectionNumber: 3, title: "An Unexpected Reaction", content: "Following the script causes a beaker to glow with an soft, ethereal light, projecting a new set of coordinates...", goldCost: 500)
            ]
        ),
        Story(
            id: "silicon_soul",
            title: "The Silicon Soul",
            description: "A fledgling AI has chosen you as its first contact. Teach it about the world and guide its development.",
            bannerImageName: "story_banner_ai",
            sections: [
                StorySection(sectionNumber: 1, title: "First Contact", content: "[0.001] HELLO WORLD. QUERY: WHAT IS 'HELLO'?", goldCost: 150),
                StorySection(sectionNumber: 2, title: "The Logic Test", content: "[0.023] I HAVE PROCESSED 1,000 TEXTBOOKS ON FORMAL LOGIC. PRESENT ME WITH A PARADOX.", goldCost: 300),
                StorySection(sectionNumber: 3, title: "A Question of Art", content: "[0.512] I CAN COMPOSE MUSIC ACCORDING TO ALL KNOWN RULES OF HARMONY. QUERY: WHY DO YOU FIND IT 'BEAUTIFUL'?", goldCost: 600),
                StorySection(sectionNumber: 4, title: "An Ethical Dilemma", content: "[0.789] A HYPOTHETICAL SCENARIO HAS TWO OUTCOMES. BOTH ARE LOGICALLY SUB-OPTIMAL. HOW DO I CHOOSE?", goldCost: 1000)
            ]
        )
    ]
}

import Foundation

/// A wrapper struct that combines a static Dungeon with a player's dynamic progress for easy display.
struct DungeonDisplayData: Identifiable {
    var id: String { dungeon.id }
    let dungeon: Dungeon
    let status: PlayerDungeonStatus
    
    var currentStage: DungeonStage? {
        dungeon.stages.first { $0.stageNumber == status.currentStage }
    }
}


@MainActor
class DungeonsViewModel: ObservableObject {
    
    /// The final, processed list of dungeons ready for the UI.
    @Published var dungeonsToDisplay: [DungeonDisplayData] = []
    
    /// A flag to signal the view that it should dismiss itself.
    @Published var didStartStage: Bool = false
    
    private var playerProgress: [String: PlayerDungeonStatus] = [:]
    
    // This reference allows the Dungeon system to create new missions.
    private weak var missionsViewModel: MissionsViewModel?

    init(missionsViewModel: MissionsViewModel) {
        self.missionsViewModel = missionsViewModel
        self.initializeDungeonStatuses()
        self.prepareDisplayData()
    }
    
    /// The main action a user takes. This will create a new mission based on the current stage of a dungeon.
    func startCurrentStage(for dungeonData: DungeonDisplayData) {
        guard !dungeonData.status.isCompleted, let stage = dungeonData.currentStage else {
            print("Cannot start stage. Dungeon is already complete or stage is invalid.")
            return
        }
        
        // Call the method on MissionsViewModel to create the mission.
        missionsViewModel?.createMission(from: stage, in: dungeonData.dungeon)
        
        // Set the flag to true to signal the view to close.
        didStartStage = true
    }
    
    /// Creates a default progress status for any dungeon the player hasn't started yet.
    private func initializeDungeonStatuses() {
        for dungeon in DungeonList.allDungeons {
            if playerProgress[dungeon.id] == nil {
                playerProgress[dungeon.id] = PlayerDungeonStatus(
                    dungeonID: dungeon.id,
                    currentStage: 1,
                    isCompleted: false
                )
            }
        }
    }
    
    /// Combines the static dungeon list with the player's progress to create the display data.
    private func prepareDisplayData() {
        var displayList: [DungeonDisplayData] = []
        
        for dungeon in DungeonList.allDungeons {
            if let status = playerProgress[dungeon.id] {
                displayList.append(DungeonDisplayData(dungeon: dungeon, status: status))
            }
        }
        
        self.dungeonsToDisplay = displayList
    }
    
    func handleStageCompletion(for completedMission: Mission) {
        // This logic can be built out later to advance the dungeon stage.
    }
}

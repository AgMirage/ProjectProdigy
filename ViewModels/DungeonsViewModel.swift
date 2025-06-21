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
    
    // --- EDITED: This is now a weak reference to the MainViewModel. ---
    private weak var mainViewModel: MainViewModel?
    private weak var missionsViewModel: MissionsViewModel?

    init(missionsViewModel: MissionsViewModel, mainViewModel: MainViewModel) {
        self.missionsViewModel = missionsViewModel
        self.mainViewModel = mainViewModel
        self.initializeDungeonStatuses()
        self.prepareDisplayData()
    }
    
    /// The main action a user takes. This will create a new mission based on the current stage of a dungeon.
    func startCurrentStage(for dungeonData: DungeonDisplayData) {
        guard let missionsVM = self.missionsViewModel else {
            print("MissionsViewModel not available.")
            return
        }
        
        guard !dungeonData.status.isCompleted, let stage = dungeonData.currentStage else {
            print("Cannot start stage. Dungeon is already complete or stage is invalid.")
            return
        }
        
        // Call the method on MissionsViewModel to create the mission.
        missionsVM.createMission(from: stage, in: dungeonData.dungeon)
        
        // Set the flag to true to signal the view to close.
        didStartStage = true
    }
    
    /// Creates a default progress status for any dungeon the player hasn't started yet.
    private func initializeDungeonStatuses() {
        guard var player = mainViewModel?.player else { return }

        for dungeon in DungeonList.allDungeons {
            if player.dungeonProgress[dungeon.id] == nil {
                player.dungeonProgress[dungeon.id] = PlayerDungeonStatus(
                    dungeonID: dungeon.id,
                    currentStage: 1,
                    isCompleted: false
                )
            }
        }
        mainViewModel?.player = player
    }
    
    /// Combines the static dungeon list with the player's progress to create the display data.
    private func prepareDisplayData() {
        guard let playerProgress = mainViewModel?.player.dungeonProgress else { return }
        var displayList: [DungeonDisplayData] = []
        
        for dungeon in DungeonList.allDungeons {
            if let status = playerProgress[dungeon.id] {
                displayList.append(DungeonDisplayData(dungeon: dungeon, status: status))
            }
        }
        
        self.dungeonsToDisplay = displayList
    }
    
    // --- EDITED: This function is no longer needed here, it will be handled in MainViewModel ---
    // func handleStageCompletion(for completedMission: Mission) { }
}

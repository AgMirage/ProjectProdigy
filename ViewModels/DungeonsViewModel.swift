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
    
    // --- EDITED: This is now a strong reference to prevent it from being deallocated. ---
    private var mainViewModel: MainViewModel
    private weak var missionsViewModel: MissionsViewModel?

    init(missionsViewModel: MissionsViewModel, mainViewModel: MainViewModel) {
        self.missionsViewModel = missionsViewModel
        self.mainViewModel = mainViewModel
    }
    
    /// A safe place to initialize the view's data.
    func loadDungeonData() {
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
        
        missionsVM.createMission(from: stage, in: dungeonData.dungeon)
        
        didStartStage = true
    }
    
    /// Creates a default progress status for any dungeon the player hasn't started yet.
    private func initializeDungeonStatuses() {
        // --- EDITED: References to mainViewModel no longer need to be optional. ---
        var player = mainViewModel.player

        for dungeon in DungeonList.allDungeons {
            if player.dungeonProgress[dungeon.id] == nil {
                player.dungeonProgress[dungeon.id] = PlayerDungeonStatus(
                    dungeonID: dungeon.id,
                    currentStage: 1,
                    isCompleted: false
                )
            }
        }
        mainViewModel.player = player
    }
    
    /// Combines the static dungeon list with the player's progress to create the display data.
    private func prepareDisplayData() {
        // --- EDITED: References to mainViewModel no longer need to be optional. ---
        let playerProgress = mainViewModel.player.dungeonProgress
        var displayList: [DungeonDisplayData] = []
        
        for dungeon in DungeonList.allDungeons {
            if let status = playerProgress[dungeon.id] {
                displayList.append(DungeonDisplayData(dungeon: dungeon, status: status))
            }
        }
        
        self.dungeonsToDisplay = displayList
    }
}

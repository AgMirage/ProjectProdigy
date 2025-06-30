import SwiftUI

struct BossBattleView: View {
    
    @StateObject private var viewModel: BossBattleViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // --- NEW: Access to knowledge tree for pickers ---
    @EnvironmentObject var knowledgeTreeViewModel: KnowledgeTreeViewModel
    
    init(mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: BossBattleViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let battle = viewModel.activeBossBattle {
                    ActiveBossBattleView(battle: battle)
                } else {
                    // --- EDITED: Pass knowledge tree to the creation view ---
                    CreateBossBattleView(knowledgeTree: knowledgeTreeViewModel.subjects)
                }
            }
            .navigationTitle("Boss Battles")
            .background(Color.groupedBackground)
            .alert(item: $viewModel.alertItem) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
        .environmentObject(viewModel)
    }
}


// MARK: - Helper View: CreateBossBattleView
struct CreateBossBattleView: View {
    @EnvironmentObject var viewModel: BossBattleViewModel
    let knowledgeTree: [Subject]
    
    var body: some View {
        // --- EDITED: Check if the feature is unlocked ---
        if let gatingMessage = viewModel.gatingMessage {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Feature Locked")
                    .font(.title.bold())
                Text(gatingMessage)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .padding()
        } else {
            // --- The new, detailed form ---
            Form {
                Section(header: Text("Declare a New Battle")) {
                    TextField("Event Name (e.g., CHEM 201 Final)", text: $viewModel.battleName)
                    
                    Picker("Subject", selection: $viewModel.selectedSubject) {
                        Text("Select Subject...").tag(nil as Subject?)
                        ForEach(knowledgeTree) { Text($0.name).tag($0 as Subject?) }
                    }
                    
                    Picker("Branch", selection: $viewModel.selectedBranch) {
                        Text("Select Branch...").tag(nil as KnowledgeBranch?)
                        if let branches = viewModel.selectedSubject?.branches.filter({ $0.isUnlocked }) {
                            ForEach(branches) { Text($0.name).tag($0 as KnowledgeBranch?) }
                        }
                    }
                    .disabled(viewModel.selectedSubject == nil)
                }
                
                Section(header: Text("Battle Configuration")) {
                    Picker("Battle Type", selection: $viewModel.battleType) {
                        ForEach(BossBattleType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("Battle Date", selection: $viewModel.battleDate, in: Date()..., displayedComponents: .date)
                    
                    HStack {
                        Text("Expected Duration (Hours)")
                        TextField("Hours", text: $viewModel.battleDurationHours)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
                
                Section(header: Text("Wager")) {
                    TextField("Gold Wager", text: $viewModel.wagerAmount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                
                Section(
                    footer: Text("The wagered Gold will be deducted immediately. If you are victorious, you will win your wager back plus a massive jackpot!")
                ) {
                    Button("Declare Battle!") {
                        viewModel.declareNewBattle()
                    }
                    .disabled(viewModel.battleName.isEmpty || viewModel.wagerAmount.isEmpty || viewModel.selectedBranch == nil)
                }
            }
        }
    }
}


// MARK: - Helper View: ActiveBossBattleView
struct ActiveBossBattleView: View {
    let battle: Mission
    @EnvironmentObject var viewModel: BossBattleViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text(battle.topicName)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("Wagered: \(battle.goldWager ?? 0) Gold")
                .font(.title2)
                .foregroundColor(.secondary)
            
            if let date = battle.scheduledDate {
                Text("Scheduled for: \(date, style: .date)")
                    .font(.headline)
            }

            Spacer()
            
            Text("Report the final outcome:")
                .font(.subheadline)
            
            HStack(spacing: 20) {
                Button(action: { viewModel.reportVictory() }) {
                    Label("I Was Victorious", systemImage: "checkmark.shield.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Button(action: { viewModel.reportDefeat() }) {
                    Label("I Was Defeated", systemImage: "xmark.shield.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
        }
        .padding()
    }
}


// MARK: - Preview
struct BossBattleView_Previews: PreviewProvider {
    static var previews: some View {
        let mainVM = MainViewModel(player: Player(username: "Preview"))
        mainVM.player.archivedMissions = (1...10).map { _ in Mission.sample } // For previewing unlocked state
        
        return BossBattleView(mainViewModel: mainVM)
            .environmentObject(KnowledgeTreeViewModel())
    }
}


// MARK: - Cross-Platform Color Helpers
fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    #endif
}

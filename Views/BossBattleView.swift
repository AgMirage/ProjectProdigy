import SwiftUI

struct BossBattleView: View {
    
    @StateObject private var viewModel: BossBattleViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    init(mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: BossBattleViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let battle = viewModel.activeBossBattle {
                    ActiveBossBattleView(battle: battle)
                } else {
                    CreateBossBattleView()
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
    
    var body: some View {
        Form {
            Section(header: Text("Declare a New Battle")) {
                TextField("Event Name (e.g., CHEM 201 Final)", text: $viewModel.battleName)
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
                .disabled(viewModel.battleName.isEmpty || viewModel.wagerAmount.isEmpty)
            }
            
            // --- ADDED: Spacer to push the form content to the top ---
            Spacer()
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
            
            Text("Awaiting Outcome...")
                .font(.headline)
                .padding(.top)

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
        BossBattleView(mainViewModel: mainVM)
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

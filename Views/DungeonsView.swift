import SwiftUI

struct DungeonsView: View {
    
    @StateObject private var viewModel: DungeonsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(missionsViewModel: MissionsViewModel, mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: DungeonsViewModel(missionsViewModel: missionsViewModel, mainViewModel: mainViewModel))
    }
    
    var body: some View {
        // --- EDITED: Removed the unnecessary NavigationStack ---
        // A toolbar is added to provide a title and a Done button.
        VStack {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.dungeonsToDisplay) { dungeonData in
                        DungeonRowView(dungeonData: dungeonData)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Dungeons")
        .background(Color.groupedBackground)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onChange(of: viewModel.didStartStage) {
            if viewModel.didStartStage {
                dismiss()
            }
        }
        .onAppear {
            viewModel.loadDungeonData()
        }
        // --- EDITED: Give the sheet a sensible default size on macOS ---
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #endif
        .environmentObject(viewModel)
    }
}

// MARK: - Helper View: DungeonRowView
struct DungeonRowView: View {
    let dungeonData: DungeonDisplayData
    @EnvironmentObject var viewModel: DungeonsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- Header ---
            HStack {
                Image(dungeonData.dungeon.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading) {
                    Text(dungeonData.dungeon.name)
                        .font(.headline)
                    Text(dungeonData.dungeon.subjectName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            // --- Description ---
            Text(dungeonData.dungeon.description)
                .font(.subheadline)
                .padding(.bottom, 5)
            
            Divider()
            
            // --- Progress & Action ---
            if dungeonData.status.isCompleted {
                // --- Completed State ---
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed!")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.green)
                }
            } else if let currentStage = dungeonData.currentStage {
                // --- In-Progress State ---
                VStack(alignment: .leading, spacing: 8) {
                    Text("Progress: Stage \(currentStage.stageNumber) of \(dungeonData.dungeon.stages.count)")
                        .font(.caption.bold())
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Next Stage:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentStage.name)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Button("Start Stage") {
                            viewModel.startCurrentStage(for: dungeonData)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .opacity(dungeonData.status.isCompleted ? 0.6 : 1.0)
    }
}


// MARK: - Preview
struct DungeonsView_Previews: PreviewProvider {
    static var previews: some View {
        let mainVM = MainViewModel(player: Player(username: "Preview"))
        let missionsVM = MissionsViewModel(mainViewModel: mainVM)
        DungeonsView(missionsViewModel: missionsVM, mainViewModel: mainVM)
    }
}

// MARK: - Cross-Platform Color Helpers
fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    static var secondaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}

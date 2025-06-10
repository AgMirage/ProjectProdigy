import SwiftUI

struct KnowledgeTreeView: View {
    
    @StateObject private var viewModel = KnowledgeTreeViewModel()
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                SubjectSidebarView(
                    subjects: viewModel.fullTree,
                    selectedSubject: $viewModel.selectedSubject
                ) { subject in
                    viewModel.selectSubject(subject)
                }

                BranchScrollView()
            }
            .navigationTitle("Knowledge Tree")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                viewModel.reinitialize(with: mainViewModel)
            }
            .sheet(item: $viewModel.branchToSetMastery) { branch in
                MasteryGoalSheetView(branch: branch)
            }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Subject Sidebar View
struct SubjectSidebarView: View {
    let subjects: [Subject]
    @Binding var selectedSubject: Subject?
    let onSelect: (Subject) -> Void

    var body: some View {
        VStack(spacing: 15) {
            ForEach(subjects) { subject in
                Button(action: { onSelect(subject) }) {
                    Image(systemName: subject.iconName)
                        .font(.title2)
                        .frame(width: 30, height: 30)
                        .padding(10)
                        .background(selectedSubject?.id == subject.id ? Color.blue.opacity(0.3) : Color.clear)
                        .clipShape(Circle())
                }
            }
            Spacer()
        }
        .padding(.vertical, 20)
        .frame(width: 80)
        .background(Color.secondaryBackground)
    }
}

// MARK: - Branch Scroll View
struct BranchScrollView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel

    var body: some View {
        VStack {
            Picker("Filter Level", selection: $viewModel.levelFilter) {
                Text("All").tag(nil as BranchLevel?)
                ForEach(BranchLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level as BranchLevel?)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            ScrollView {
                if viewModel.selectedSubject != nil {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.filteredBranches) { branch in
                            BranchView(branch: branch)
                        }
                    }
                    .padding()
                } else {
                    Text("Select a subject to begin.").font(.headline)
                        .foregroundColor(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.groupedBackground)
    }
}

// MARK: - Branch View
struct BranchView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let branch: KnowledgeBranch
    
    // --- NEW: State to control the hover popover ---
    @State private var isShowingTooltip = false
    
    private var currentMasteryGoal: MasteryLevel? {
        viewModel.player?.branchMasteryLevels[branch.name]?.level
    }
    
    private var xpGoal: Double {
        let multiplier = currentMasteryGoal?.multiplier ?? 1.0
        return branch.totalXpRequired > 0 ? (branch.totalXpRequired * multiplier) : 5000
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(branch.name)
                    .font(.title2.bold())
                Text("(\(branch.level.rawValue))")
                    .font(.caption).foregroundColor(.secondary)
                    .padding(5).background(branch.level == .college ? Color.purple.opacity(0.2) : Color.green.opacity(0.2)).cornerRadius(8)
                Spacer()
                if !branch.isUnlocked {
                    Image(systemName: "lock.fill").foregroundColor(.secondary)
                } else {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.blue)
                }
            }
            
            Text(branch.description).font(.caption).foregroundColor(.secondary)
            
            if !branch.isUnlocked, let goal = currentMasteryGoal {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.accentColor)
                    Text("Current Goal: \(goal.rawValue)")
                        .font(.footnote.bold())
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, 4)
                // --- FIXED: Replaced .help with a more reliable .onHover and .popover combination ---
                .onHover(perform: { hovering in
                    isShowingTooltip = hovering
                })
                .popover(isPresented: $isShowingTooltip, arrowEdge: .bottom) {
                    Text(masteryRequirementsTooltip(goal: goal))
                        .padding()
                }
            }
            
            ProgressView(value: branch.currentXP, total: xpGoal).tint(branch.isUnlocked ? .blue : .gray)
            Divider().padding(.bottom, 5)

            if branch.isUnlocked {
                VStack(alignment: .leading) {
                    ForEach(branch.topics) { topic in
                        TopicView(topic: topic, parentBranch: branch)
                    }
                }
                .padding(.leading, 10)
            } else {
                RequirementsView(branch: branch)
            }
        }
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .opacity(branch.isUnlocked ? 1.0 : 0.7)
    }
    
    private func masteryRequirementsTooltip(goal: MasteryLevel) -> String {
        let multiplier = goal.multiplier
        let requiredXP = branch.totalXpRequired * multiplier
        let requiredMissions = Int(Double(branch.totalMissionsRequired) * multiplier)
        let requiredTime = branch.totalTimeRequired * multiplier
        
        let hours = requiredTime / 3600
        let formattedHours = String(format: "%.1f", hours)
        
        return """
        Goal: \(goal.rawValue) (\(String(format: "%.2f", multiplier))x)
        --------------------
        Required XP: \(Int(requiredXP))
        Required Missions: \(requiredMissions)
        Required Time: \(formattedHours) hours
        """
    }
}

// MARK: - Topic View
struct TopicView: View {
    let topic: KnowledgeTopic
    let parentBranch: KnowledgeBranch
    
    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = seconds / 3600
        return String(format: "%.1f", hours)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: topic.isUnlocked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(topic.isUnlocked ? .green : .secondary).font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.name).font(.body)
                    .strikethrough(topic.isUnlocked, color: .secondary)
                    .foregroundColor(topic.isUnlocked ? .secondary : .primary)
                
                if !topic.isUnlocked {
                    Text("Requires: \(topic.missionsRequired) missions, \(formatHours(topic.timeRequired)) hrs, \(Int(topic.xpRequired)) XP in this branch.")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Requirements View
struct RequirementsView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let branch: KnowledgeBranch
    @State private var showConfirmationAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.canAttemptUnlock(for: branch) {
                
                if viewModel.player?.branchMasteryLevels[branch.name] != nil {
                    Button(action: { showConfirmationAlert = true }) {
                        Label("Change Mastery Goal", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: { viewModel.branchToSetMastery = branch }) {
                        Label("Set Mastery Goal & Unlock", systemImage: "key.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                
            } else {
                Text("Requirements to Unlock:").font(.headline).foregroundColor(.secondary)
                if !branch.prerequisiteBranchNames.isEmpty {
                    RequirementRow(icon: "books.vertical.fill", text: "Complete \(Int(branch.prerequisiteCompletion * 100))% of: \(branch.prerequisiteBranchNames.joined(separator: ", "))")
                }
                if let requiredStats = branch.requiredStats {
                    ForEach(requiredStats.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        RequirementRow(icon: "star.fill", text: "Requires \(key) Stat of \(value)")
                    }
                }
            }
        }
        .alert("Change Mastery Goal?", isPresented: $showConfirmationAlert) {
            Button("Confirm", role: .destructive) {
                viewModel.branchToSetMastery = branch
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure? Your progress towards the current goal will be kept, but the requirements will be updated.")
        }
    }
}

struct RequirementRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon).font(.caption).foregroundColor(.blue).frame(width: 20)
            Text(text).font(.caption).foregroundColor(.primary)
        }
    }
}

// MARK: - Mastery Goal Sheet View
struct MasteryGoalSheetView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    @Environment(\.dismiss) var dismiss
    let branch: KnowledgeBranch
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Mastery Goal").font(.largeTitle.bold())
            Text(branch.name).font(.title2).foregroundColor(.secondary)
            Divider()
            Text("Choose your goal for this branch. Higher goals require more effort but grant greater rewards upon completion.").font(.subheadline).multilineTextAlignment(.center).padding(.horizontal)

            VStack(spacing: 15) {
                ForEach(MasteryLevel.allCases, id: \.self) { level in
                    Button(action: {
                        viewModel.setMasteryGoal(for: branch, level: level)
                        dismiss()
                    }) {
                        VStack {
                            Text(level.rawValue).font(.headline)
                            Text("(\(String(format: "%.2f", level.multiplier))x Requirements & Rewards)").font(.caption).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                Button("Custom (Coming Soon)") {}.buttonStyle(.bordered).disabled(true)
            }
            .padding()
            
            Button("Cancel", role: .cancel) { dismiss() }
        }
        .padding()
        // On macOS, give the sheet a reasonable default size
        #if os(macOS)
        .frame(width: 400, height: 450)
        #endif
    }
}

// MARK: - Preview
struct KnowledgeTreeView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "PreviewUser")
        let mainViewModel = MainViewModel(player: player)
        KnowledgeTreeView().environmentObject(mainViewModel)
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

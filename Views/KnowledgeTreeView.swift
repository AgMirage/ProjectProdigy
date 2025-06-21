import SwiftUI

struct KnowledgeTreeView: View {
    
    // --- EDITED: This now gets the single source of truth from the environment. ---
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                SubjectSidebarView(
                    subjects: viewModel.subjects,
                    selectedSubject: $viewModel.selectedSubject
                )
                
                if let selectedSubject = viewModel.selectedSubject {
                    BranchScrollView(subject: selectedSubject)
                } else {
                    VStack {
                        Text("Select a subject to begin.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Knowledge Tree")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // --- REMOVED: The onAppear logic is now handled by the parent MainView. ---
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
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(subjects) { subject in
                Button(action: { selectedSubject = subject }) {
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
    let subject: Subject
    @State private var showSubjectResetAlert = false
    
    var body: some View {
        VStack {
            VStack(spacing: 5) {
                HStack {
                    Picker("Filter Level", selection: $viewModel.levelFilter) {
                        Text("All").tag(nil as BranchLevel?)
                        ForEach(BranchLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level as BranchLevel?)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Button(role: .destructive) {
                        showSubjectResetAlert = true
                    } label: {
                        Image(systemName: "trash.circle.fill")
                    }
                    .font(.title2)
                }
                .padding([.horizontal, .top])
                
            }
            .alert("Reset Subject?", isPresented: $showSubjectResetAlert) {
                Button("Reset All in \(subject.name)", role: .destructive) {
                    viewModel.resetSubjectProgress(subjectID: subject.id)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all your progress for every branch within the \(subject.name) subject. This action cannot be undone.")
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.branchesToDisplay) { branch in
                        BranchView(branch: branch)
                    }
                }
                .padding()
            }
            .id(viewModel.refreshID)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.groupedBackground)
    }
}


// MARK: - Branch View
struct BranchView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let branch: KnowledgeBranch
    
    @State private var isShowingResetAlert = false
    @State private var isShowingTooltip = false
    
    private var currentMasteryGoal: MasteryLevel? {
        viewModel.player?.branchMasteryLevels[branch.name]?.level
    }
    
    private var statusIconName: String {
        if branch.isMastered { return "checkmark.seal.fill" }
        if branch.isUnlocked { return "lock.open.fill" }
        return "lock.fill"
    }
    
    private var statusColor: Color {
        if branch.isMastered { return .green }
        if branch.isUnlocked { return .blue }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: statusIconName)
                    .foregroundColor(statusColor)
                Text(branch.name)
                    .font(.title2.bold())
                Spacer()
                if branch.isMastered {
                    Button { isShowingResetAlert = true } label: {
                        // --- FIXED: Correct SF Symbol name ---
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
            
            Text(branch.description).font(.caption).foregroundColor(.secondary)
            
            if let goal = currentMasteryGoal {
                HStack(spacing: 15) {
                    HStack {
                        Image(systemName: "target")
                        Text("Goal: \(goal.rawValue)")
                    }
                    .font(.footnote.bold())
                    .foregroundColor(.accentColor)
                    .onHover { hovering in
                        isShowingTooltip = hovering
                    }
                    .popover(isPresented: $isShowingTooltip, arrowEdge: .bottom) {
                        Text(masteryRequirementsTooltip(goal: goal))
                            .padding()
                    }
                    
                    Button("(Change)") { viewModel.branchToSetMastery = branch }
                    .font(.footnote)
                }
                .padding(.top, 2)
            }
            
            ProgressView(value: branch.progress, total: 1.0) {
                HStack {
                    Text("Mastery Progress")
                    Spacer()
                    Text("\(Int(branch.progress * 100))%")
                }
                .font(.caption)
            }
            .tint(branch.isUnlocked ? .blue : .gray)
            .padding(.bottom, 5)

            Divider()

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
        .alert("Reset Branch Progress?", isPresented: $isShowingResetAlert) {
            Button("Reset", role: .destructive) {
                viewModel.resetBranchProgress(branchID: branch.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to reset your progress for the \(branch.name) branch? This will remove all accumulated XP and study time for this specific branch, and mark it as 'unlocked but not mastered' again.")
        }
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
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let topic: KnowledgeTopic
    let parentBranch: KnowledgeBranch
    @State private var showTopicResetAlert = false
    
    private var multiplier: Double {
        viewModel.player?.branchMasteryLevels[parentBranch.name]?.level.multiplier ?? 1.0
    }
    private var displayXpRequired: Int {
        Int(topic.xpRequired * multiplier)
    }
    private var displayMissionsRequired: Int {
        Int(Double(topic.missionsRequired) * multiplier)
    }
    private var displayTimeRequired: TimeInterval {
        topic.timeRequired * multiplier
    }
    
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
                    Text("Requires: \(displayMissionsRequired) missions, \(formatHours(displayTimeRequired)) hrs, \(displayXpRequired) XP in this branch.")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if topic.isUnlocked {
                Button {
                    showTopicResetAlert = true
                } label: {
                    // --- FIXED: Correct SF Symbol name ---
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
        }
        .padding(.vertical, 5)
        .alert("Reset Topic?", isPresented: $showTopicResetAlert) {
            Button("Reset Topic", role: .destructive) {
                viewModel.resetTopicProgress(topicID: topic.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your progress for the topic '\(topic.name)' and subtract its value from the branch's overall progress.")
        }
    }
}

// MARK: - Requirements View & Helpers
struct RequirementsView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let branch: KnowledgeBranch
    
    var body: some View {
        if viewModel.canAttemptUnlock(for: branch) {
            SetMasteryGoalButtonView(branch: branch)
        } else {
            LockedRequirementsTextView(branch: branch)
        }
    }
}

struct SetMasteryGoalButtonView: View {
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let branch: KnowledgeBranch
    
    var body: some View {
        Button(action: { viewModel.branchToSetMastery = branch }) {
            Label("Set Mastery Goal & Unlock", systemImage: "key.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }
}

struct LockedRequirementsTextView: View {
    let branch: KnowledgeBranch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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

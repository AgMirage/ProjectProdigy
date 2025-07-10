import SwiftUI

// --- NEW: Wrapper struct to make UUID Identifiable ---
struct BranchIdentifier: Identifiable {
    let id: UUID
}

struct KnowledgeTreeView: View {
    
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    
    // --- EDITED: Use the new Identifiable wrapper ---
    @State private var branchIDForDetailView: BranchIdentifier?

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                SubjectSidebarView(
                    subjects: viewModel.subjects,
                    selectedSubject: $viewModel.selectedSubject
                )
                
                if let selectedSubject = viewModel.selectedSubject {
                    BranchScrollView(subject: selectedSubject, branchIDForDetailView: $branchIDForDetailView)
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
            .sheet(item: $viewModel.branchToSetMastery) { branch in
                MasteryGoalSheetView(branch: branch)
                    .environmentObject(viewModel)
            }
            .sheet(item: $branchIDForDetailView) { branchIdentifier in
                if let branch = viewModel.findBranch(withID: branchIdentifier.id) {
                    NavigationStack {
                        BranchProgressDetailView(branch: branch)
                            .environmentObject(viewModel)
                    }
                }
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
    
    // --- EDITED: Use the new Identifiable wrapper ---
    @Binding var branchIDForDetailView: BranchIdentifier?

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
                        BranchView(branch: branch, branchIDForDetailView: $branchIDForDetailView)
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
    
    // --- EDITED: Use the new Identifiable wrapper ---
    @Binding var branchIDForDetailView: BranchIdentifier?
    
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
        if branch.isMastered { return .yellow }
        if branch.isUnlocked { return .blue }
        return .secondary
    }
    
    private var borderColor: Color {
        switch branch.remasterCount {
        case 1: return .gray
        case 2: return .yellow
        default: return .clear
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: statusIconName)
                    .foregroundColor(statusColor)
                Text(branch.name)
                    .font(.title2.bold())
                
                if branch.remasterCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                        Text("+\(branch.remasterCount)")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.purple)
                }
                
                Spacer()
                if branch.isMastered {
                    Button("Remaster") {
                        viewModel.branchToSetMastery = branch
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                }
            }
            
            Text(branch.description).font(.caption).foregroundColor(.secondary)
            
            if let goal = currentMasteryGoal, !branch.isMastered {
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
            
            // --- EDITED: Assign a BranchIdentifier on tap ---
            Button(action: {
                branchIDForDetailView = BranchIdentifier(id: branch.id)
            }) {
                ProgressView(value: branch.progress, total: 1.0) {
                    HStack {
                        Text("Mastery Progress")
                            .underline()
                        Spacer()
                        Text("\(Int(branch.progress * 100))%")
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .tint(branch.isMastered ? .yellow : (branch.isUnlocked ? .blue : .gray))
            }
            .buttonStyle(.plain)
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: branch.remasterCount > 0 ? 3 : 0)
        )
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
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    let topic: KnowledgeTopic
    let parentBranch: KnowledgeBranch
    @State private var showTopicResetAlert = false
    
    private var multiplier: Double {
        let masteryMultiplier = viewModel.player?.branchMasteryLevels[parentBranch.name]?.level.multiplier ?? 1.0
        let remasterMultiplier = 1.0 + (Double(parentBranch.remasterCount) * 0.25)
        return masteryMultiplier * remasterMultiplier
    }
    private var displayXpRequired: Int {
        Int(topic.xpRequired * multiplier)
    }
    private var displayMissionsRequired: Int {
        Int(ceil(Double(topic.missionsRequired) * multiplier))
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
    
    private var isRemastering: Bool {
        branch.isMastered
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isRemastering ? "Remaster Branch" : "Set Mastery Goal")
                .font(.largeTitle.bold())
            
            Text(branch.name).font(.title2).foregroundColor(.secondary)
            Divider()
            
            Text(isRemastering ? "Select a new, higher mastery goal for this branch. Requirements will be scaled up accordingly." : "Choose your goal for this branch. Higher goals require more effort but grant greater rewards upon completion.")
                .font(.subheadline).multilineTextAlignment(.center).padding(.horizontal)

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
                    .disabled(isRemastering && (viewModel.player?.branchMasteryLevels[branch.name]?.level ?? .standard) >= level)
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

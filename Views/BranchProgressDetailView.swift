import SwiftUI

/// A view that shows a detailed breakdown of the player's progress for a single KnowledgeBranch.
struct BranchProgressDetailView: View {
    
    @EnvironmentObject var viewModel: KnowledgeTreeViewModel
    @Environment(\.dismiss) var dismiss
    let branch: KnowledgeBranch
    
    @State private var isShowingShareSheet = false
    @State private var csvFileURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(branch: branch, masteryGoal: currentMasteryGoal)
                OverallProgressView(progress: branch.progress)
                
                if branch.remasterCount > 0 {
                    RemasterBonusView(remasterCount: branch.remasterCount)
                }

                CoreMetricsView(branch: branch, masteryGoal: currentMasteryGoal)
                TopicContributionsView(branch: branch)
            }
            .padding()
        }
        .background(Color.groupedBackground)
        .navigationTitle("Branch Progress")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    if let url = viewModel.exportBranchDetailToCSV(branch: branch) {
                        self.csvFileURL = url
                        self.isShowingShareSheet = true
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            #endif
        }
        #if os(iOS)
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = csvFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        #endif
    }
    
    private var currentMasteryGoal: MasteryLevel {
        viewModel.player?.branchMasteryLevels[branch.name]?.level ?? .standard
    }
}

// MARK: - Child Views

private struct HeaderView: View {
    let branch: KnowledgeBranch
    let masteryGoal: MasteryLevel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(branch.name)
                .font(.largeTitle.bold())
            Text("Mastery Goal: \(masteryGoal.rawValue)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

private struct OverallProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack {
            Text("\(Int(progress * 100))% Mastered")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            ProgressView(value: progress)
                .tint(.blue)
        }
    }
}

private struct RemasterBonusView: View {
    let remasterCount: Int
    
    private var remasterMultiplier: Double {
        1.0 + (Double(remasterCount) * 0.25)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text("Remaster Bonus: +\(Int((remasterMultiplier - 1.0) * 100))% to all requirements")
                .font(.footnote.bold())
                .foregroundColor(.purple)
            Spacer()
        }
        .padding(8)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

private struct CoreMetricsView: View {
    let branch: KnowledgeBranch
    let masteryGoal: MasteryLevel

    private var totalMultiplier: Double {
        (1.0 + (Double(branch.remasterCount) * 0.25)) * masteryGoal.multiplier
    }
    
    private var totalRequiredTime: Double {
        let total = branch.topics.reduce(0) { $0 + $1.timeRequired }
        return total * totalMultiplier
    }
    
    private var totalRequiredXP: Double {
        let total = branch.topics.reduce(0) { $0 + $1.xpRequired }
        return total * totalMultiplier
    }
    
    private var totalRequiredMissions: Double {
        let total = branch.topics.reduce(0) { $0 + Double($1.missionsRequired) }
        return total * totalMultiplier
    }
    
    private func format(duration: TimeInterval) -> String {
        let hours = duration / 3600
        if hours < 1 {
            let minutes = duration / 60
            return "\(Int(minutes))m"
        }
        return String(format: "%.1f hrs", hours)
    }
    
    var body: some View {
        VStack {
            MetricRow(
                metric: "Time Spent",
                current: format(duration: branch.totalTimeSpent),
                required: format(duration: totalRequiredTime)
            )
            Divider()
            MetricRow(
                metric: "XP Earned",
                current: "\(Int(branch.currentXP)) XP",
                required: "\(Int(totalRequiredXP)) XP"
            )
            Divider()
            MetricRow(
                metric: "Missions Done",
                current: "\(branch.missionsCompleted)",
                required: "\(Int(totalRequiredMissions))"
            )
        }
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(12)
    }
}

private struct TopicContributionsView: View {
    let branch: KnowledgeBranch
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Topic Contributions")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(branch.topics) { topic in
                TopicContributionView(topic: topic, isUnlocked: topic.isUnlocked)
            }
        }
    }
}


// MARK: - Helper Views
private struct MetricRow: View {
    let metric: String
    let current: String
    let required: String
    
    var body: some View {
        HStack {
            Text(metric)
                .font(.headline)
            Spacer()
            VStack(alignment: .trailing) {
                Text(current)
                    .font(.body.bold())
                Text("Required: \(required)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct TopicContributionView: View {
    let topic: KnowledgeTopic
    let isUnlocked: Bool
    
    private func format(duration: TimeInterval) -> String {
        let hours = duration / 3600
        return String(format: "%.1f", hours)
    }
    
    var body: some View {
        HStack {
            Image(systemName: isUnlocked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isUnlocked ? .green : .secondary)
            
            Text(topic.name)
                .strikethrough(isUnlocked)
            
            Spacer()
            
            if isUnlocked {
                HStack(spacing: 10) {
                    Text("\(Int(topic.xpRequired)) XP")
                    Text("\(format(duration: topic.timeRequired))h")
                    Text("\(topic.missionsRequired)m")
                }
                .font(.caption.bold())
                .foregroundColor(.secondary)
            } else {
                Text("Locked")
                    .font(.caption.italic())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondaryBackground)
        .cornerRadius(8)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif


fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    static var secondaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}

struct BranchProgressDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "Preview")
        let mainVM = MainViewModel(player: player)
        let knowledgeVM = KnowledgeTreeViewModel()
        knowledgeVM.reinitialize(with: mainVM)
        
        // Find a branch that is unlocked to make the preview more useful
        let sampleBranch = knowledgeVM.subjects.first!.branches.first(where: { $0.isUnlocked }) ?? knowledgeVM.subjects.first!.branches.first!
        
        return NavigationStack {
            BranchProgressDetailView(branch: sampleBranch)
                .environmentObject(knowledgeVM)
        }
    }
}

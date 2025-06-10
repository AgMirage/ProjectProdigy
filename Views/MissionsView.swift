import SwiftUI

// MARK: - Main Missions View
struct MissionsView: View {
    
    @StateObject private var viewModel: MissionsViewModel
    private var mainViewModel: MainViewModel

    init(mainViewModel: MainViewModel) {
        self.mainViewModel = mainViewModel
        _viewModel = StateObject(wrappedValue: MissionsViewModel(mainViewModel: mainViewModel))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.activeMissions) { mission in
                    MissionRowView(mission: mission)
                }
                .onDelete(perform: viewModel.deleteMission)
            }
            .navigationTitle("Missions")
            .toolbar {
                // --- FIXED: Replaced 'navigationBarTrailing' with '.primaryAction' for cross-platform compatibility ---
                ToolbarItemGroup(placement: .primaryAction) {
                    NavigationLink {
                        DungeonsView(missionsViewModel: viewModel)
                    } label: { Image(systemName: "shield.lefthalf.filled") }
                    
                    NavigationLink {
                        BossBattleView(mainViewModel: self.mainViewModel)
                    } label: { Image(systemName: "crown.fill") }
                    
                    Button(action: { viewModel.isShowingCreateSheet = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $viewModel.isShowingCreateSheet) { CreateMissionView() }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Mission Row View (Corrected)
struct MissionRowView: View {
    let mission: Mission
    @EnvironmentObject var viewModel: MissionsViewModel
    private let pomodoroStudyDuration: TimeInterval = 25 * 60
    private let pomodoroBreakDuration: TimeInterval = 5 * 60

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(mission.subjectName) / \(mission.branchName)").font(.caption).foregroundColor(.secondary)
                    Text(mission.topicName).font(.headline).bold()
                    HStack {
                        Image(systemName: mission.studyType.iconName)
                        Text(mission.studyType.displayString)
                    }.font(.subheadline).foregroundColor(.blue)
                }
                if mission.isPomodoro {
                    Spacer()
                    VStack { Image(systemName: "timer").font(.title); Text("POMODORO").font(.caption).bold() }.foregroundColor(.purple)
                }
            }
            VStack {
                // Correctly display Pomodoro status text only when in progress
                if mission.isPomodoro && mission.status == .inProgress {
                    Text(mission.isBreakTime ? "Break Time!" : "Focus Cycle: \(mission.pomodoroCycle)")
                        .font(.headline).foregroundColor(mission.isBreakTime ? .green : .purple)
                }
                
                ProgressView(value: progressValue, total: progressTotal)
                    .tint(mission.status == .inProgress ? (mission.isBreakTime ? .green : .purple) : .blue)
                
                HStack {
                    Text(formatTime(mission.timeRemaining)).font(.system(size: 36, weight: .bold, design: .monospaced))
                    Spacer()
                    // Don't show total duration for pomodoro missions, as it's not a single block
                    if !mission.isPomodoro { Text(formatTime(mission.totalDuration)).font(.system(size: 18, weight: .semibold, design: .monospaced)).foregroundColor(.secondary) }
                }
            }
            HStack {
                if mission.status == .pending || mission.status == .paused {
                    Button(action: { viewModel.startMission(mission: mission) }) { Label(mission.status == .pending ? "Start" : "Resume", systemImage: "play.fill") }.buttonStyle(.borderedProminent).tint(.green)
                } else if mission.status == .inProgress {
                    Button(action: { viewModel.pauseMission(mission: mission) }) { Label("Pause", systemImage: "pause.fill") }.buttonStyle(.borderedProminent).tint(.orange)
                }
                Spacer()
                if mission.status == .inProgress || mission.status == .paused {
                    Button(action: { viewModel.completeMission(mission: mission) }) { Label("Complete", systemImage: "checkmark") }.buttonStyle(.bordered).tint(.blue)
                }
            }.padding(.top, 5)
        }.padding(.vertical, 10)
    }
    
    // Corrected logic for progress bar display
    private var progressValue: Double {
        if mission.isPomodoro {
            let total = mission.isBreakTime ? pomodoroBreakDuration : pomodoroStudyDuration
            return total - mission.timeRemaining
        } else {
            return mission.totalDuration - mission.timeRemaining
        }
    }
    
    private var progressTotal: Double {
        if mission.isPomodoro {
            return mission.isBreakTime ? pomodoroBreakDuration : pomodoroStudyDuration
        } else {
            return mission.totalDuration
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


// MARK: - Create Mission Sheet View (Corrected)
struct CreateMissionView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                topicSection
                detailsSection
                createButtonSection
            }
            .navigationTitle("New Mission")
            // --- FIXED: This modifier is unavailable on macOS, so we wrap it for iOS only. ---
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                // --- FIXED: Changed placement to '.cancellationAction' for cross-platform compatibility ---
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var topicSection: some View {
        Section("Select Topic") {
            Picker("Subject", selection: $viewModel.selectedSubject) {
                Text("Select Subject...").tag(nil as Subject?)
                ForEach(viewModel.knowledgeTree) { Text($0.name).tag($0 as Subject?) }
            }.onChange(of: viewModel.selectedSubject) {
                viewModel.selectedBranch = nil
                viewModel.selectedStudyType = nil
            }
            
            Picker("Branch", selection: $viewModel.selectedBranch) {
                Text("Select Branch...").tag(nil as KnowledgeBranch?)
                if let branches = viewModel.selectedSubject?.branches.filter({ $0.isUnlocked }) {
                    ForEach(branches) { Text($0.name).tag($0 as KnowledgeBranch?) }
                }
            }.disabled(viewModel.selectedSubject == nil)
             .onChange(of: viewModel.selectedBranch) { viewModel.selectedTopic = nil }
            
            Picker("Topic", selection: $viewModel.selectedTopic) {
                Text("Select Topic...").tag(nil as KnowledgeTopic?)
                if let topics = viewModel.selectedBranch?.topics.filter({ $0.isUnlocked }) {
                    ForEach(topics) { Text($0.name).tag($0 as KnowledgeTopic?) }
                }
            }.disabled(viewModel.selectedBranch == nil)
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Mission Details"), footer: Text("Pomodoro breaks your session into focused work intervals (25 min) and short breaks (5 min).")) {
            Picker("Study Type", selection: $viewModel.selectedStudyType) {
                Text("Select Study Type...").tag(nil as StudyType?)
                ForEach(viewModel.availableStudyTypes, id: \.self) { Text($0.displayString).tag($0 as StudyType?) }
            }.disabled(viewModel.selectedSubject == nil)
            
            Toggle("Enable Pomodoro Mode", isOn: $viewModel.isPomodoroEnabled)
            
            HStack {
                Text("Duration")
                Spacer()
                // --- FIXED: '.wheel' is not available on macOS. Changed to '.menu'. ---
                Picker("Hours", selection: $viewModel.missionHours) { ForEach(0..<24) { Text("\($0) hr").tag($0) } }.pickerStyle(.menu)
                Picker("Minutes", selection: $viewModel.missionMinutes) { ForEach(0..<60) { Text("\($0) min").tag($0) } }.pickerStyle(.menu)
            }
        }
    }
    
    private var createButtonSection: some View {
        let isInvalid = viewModel.selectedSubject == nil || viewModel.selectedBranch == nil || viewModel.selectedTopic == nil || viewModel.selectedStudyType == nil
        return Section { Button("Create Mission") { viewModel.createMission() }.disabled(isInvalid) }
    }
}


// MARK: - Previews
struct MissionsView_Previews: PreviewProvider {
    static var previews: some View {
        MissionsView(mainViewModel: MainViewModel(player: Player(username: "Preview")))
    }
}

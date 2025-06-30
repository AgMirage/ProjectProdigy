import SwiftUI

// MARK: - Main Missions View
struct MissionsView: View {
    
    @EnvironmentObject var viewModel: MissionsViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var knowledgeTreeViewModel: KnowledgeTreeViewModel

    var body: some View {
        #if os(macOS)
        missionsContent
        #else
        NavigationStack {
            missionsContent
        }
        #endif
    }
    
    private var missionsContent: some View {
        VStack {
            HStack {
                Picker("Status", selection: $viewModel.statusFilter) {
                    Text("All Statuses").tag(nil as MissionStatus?)
                    ForEach(MissionStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status as MissionStatus?)
                    }
                }
                .pickerStyle(.menu)
                
                Picker("Source", selection: $viewModel.sourceFilter) {
                    Text("All Sources").tag(nil as MissionSource?)
                    ForEach([MissionSource.manual, .automatic, .dungeon, .guild], id: \.self) { source in
                        Text(source.rawValue.capitalized).tag(source as MissionSource?)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            List {
                ForEach(viewModel.filteredAndSortedMissions) { mission in
                    MissionRowView(mission: mission)
                }
                .onDelete(perform: viewModel.deleteMission)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Missions")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                NavigationLink {
                    DungeonsView(missionsViewModel: viewModel, mainViewModel: self.mainViewModel)
                } label: { Image(systemName: "shield.lefthalf.filled") }
                
                NavigationLink {
                    BossBattleView(mainViewModel: self.mainViewModel)
                } label: { Image(systemName: "crown.fill") }
                
                Button(action: { viewModel.isShowingCreateSheet = true }) { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            CreateMissionView()
                .onAppear {
                    viewModel.knowledgeTree = knowledgeTreeViewModel.subjects
                }
        }
        .sheet(item: $mainViewModel.missionToReview) { mission in
             MissionReviewView(
                 mission: mission,
                 missionToReview: $mainViewModel.missionToReview,
                 onReviewSubmit: { focus, understanding, challenge in
                     mainViewModel.submitMissionReview(for: mission.id, focus: focus, understanding: understanding, challenge: challenge)
                     mainViewModel.archiveMission(mission)
                 }
             )
         }
    }
}

// MARK: - Mission Row View
struct MissionRowView: View {
    // --- EDITED: Changed from let to @ObservedObject ---
    @ObservedObject var mission: Mission
    
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
                Spacer()
                Button(action: {
                    viewModel.togglePin(for: mission)
                }) {
                    Image(systemName: mission.isPinned ? "pin.fill" : "pin")
                        .font(.title2)
                        .foregroundColor(mission.isPinned ? .yellow : .gray)
                }
                .buttonStyle(.plain)
            }
            VStack {
                if mission.isPomodoro && mission.status == .inProgress {
                    Text(mission.isBreakTime ? "Break Time!" : "Focus Cycle: \(mission.pomodoroCycle)")
                        .font(.headline).foregroundColor(mission.isBreakTime ? .green : .purple)
                }
                
                ProgressView(value: progressValue, total: progressTotal)
                    .tint(mission.status == .inProgress ? (mission.isBreakTime ? .green : .purple) : .blue)
                
                HStack {
                    Text(formatTime(mission.timeRemaining)).font(.system(size: 36, weight: .bold, design: .monospaced))
                    Spacer()
                    if !mission.isPomodoro { Text(formatTime(mission.totalDuration)).font(.system(size: 18, weight: .semibold, design: .monospaced)).foregroundColor(.secondary) }
                }
            }
            
            HStack(spacing: 8) {
                switch mission.status {
                case .pending:
                    Button(action: { viewModel.startMission(mission: mission) }) {
                        Label("Start", systemImage: "play.fill").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.green)
                    
                case .paused:
                    Button(action: { viewModel.startMission(mission: mission) }) {
                        Label("Resume", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(.green)
                    
                    Button(action: { viewModel.completeMission(mission: mission) }) {
                        Label("Complete", systemImage: "checkmark")
                    }
                    .buttonStyle(.bordered).tint(.blue)

                case .inProgress:
                    Button(action: { viewModel.pauseMission(mission: mission) }) {
                        Label("Pause", systemImage: "pause.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(.orange)
                    
                    Button(action: { viewModel.completeMission(mission: mission) }) {
                        Label("Complete", systemImage: "checkmark")
                    }
                    .buttonStyle(.bordered).tint(.blue)

                case .failed:
                    Button(action: { viewModel.retryMission(mission: mission) }) {
                        Label("Retry", systemImage: "arrow.counterclockwise").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent).tint(.orange)
                
                case .completed:
                    Text("Completed")
                        .font(.headline.bold())
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.top, 5)

        }.padding(.vertical, 10)
    }
    
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


// MARK: - Create Mission Sheet View
struct CreateMissionView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isScheduling: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                topicSection
                detailsSection
                
                Section(header: Text("Scheduling")) {
                    Toggle("Schedule for Later?", isOn: $isScheduling.animation())
                    
                    if isScheduling {
                        DatePicker(
                            "Scheduled Time",
                            selection: Binding(
                                get: { viewModel.scheduledDate ?? Date() },
                                set: { viewModel.scheduledDate = $0 }
                            ),
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
                
                createButtonSection
            }
            .navigationTitle("New Mission")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
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

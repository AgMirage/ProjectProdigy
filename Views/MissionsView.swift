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
            Picker("View", selection: $viewModel.selectedTab) {
                ForEach(MissionListTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            switch viewModel.selectedTab {
            case .active, .scheduled:
                missionListView
            case .planner:
                MonthlyCalendarView()
            case .completed:
                ArchiveView(archivedMissions: mainViewModel.archivedMissions)
            }
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
    
    private var missionListView: some View {
        List {
            ForEach(viewModel.filteredAndSortedMissions) { mission in
                MissionRowView(mission: mission)
            }
            .onDelete(perform: viewModel.deleteMission)
        }
        .listStyle(.plain)
    }
}


// MARK: - Monthly Calendar View
struct MonthlyCalendarView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    @State private var date = Date()
    
    private var days: [Date] {
        generateDaysInMonth(for: date)
    }
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            // Header with month navigation
            HStack {
                Button(action: {
                    date = calendar.date(byAdding: .month, value: -1, to: date) ?? date
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(date.formatted(.dateTime.month(.wide).year()))
                    .font(.title2.bold())
                Spacer()
                Button(action: {
                    date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            // Header for weekday names
            let weekdaySymbols = calendar.shortWeekdaySymbols
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Grid for the days and missions
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(days, id: \.self) { day in
                    CalendarDayCell(
                        day: day,
                        missions: viewModel.missions(for: day),
                        isFaded: !calendar.isDate(day, equalTo: date, toGranularity: .month)
                    )
                }
            }
        }
        .background(Color.groupedBackground)
    }
    
    private func generateDaysInMonth(for date: Date) -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        let firstDayOfMonth = monthInterval.start.startOfDay(using: calendar)

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToAddBefore = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        guard let startingDay = calendar.date(byAdding: .day, value: -daysToAddBefore, to: firstDayOfMonth) else {
            return []
        }
        
        var allDays: [Date] = []
        for i in 0..<42 {
            if let day = calendar.date(byAdding: .day, value: i, to: startingDay) {
                allDays.append(day)
            }
        }
        return allDays
    }
}

struct CalendarDayCell: View {
    let day: Date
    let missions: [Mission]
    let isFaded: Bool
    
    private let calendar = Calendar.current
    private var isToday: Bool { calendar.isDateInToday(day) }
    
    var body: some View {
        VStack(spacing: 4) {
            // --- EDITED: Content is now conditional ---
            if !isFaded {
                Text(day.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isToday ? .heavy : .regular))
                    .frame(width: 24, height: 24)
                    .background(isToday ? Color.accentColor : Color.clear)
                    .foregroundColor(isToday ? .white : .primary)
                    .clipShape(Circle())
                
                VStack(spacing: 4) {
                    if missions.isEmpty {
                        Spacer()
                    } else {
                        ForEach(missions) { mission in
                            Text(mission.topicName)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                }
            } else {
                // If the day is not in the current month, show an empty spacer
                Spacer()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
        .background(Color.secondaryBackground)
        .cornerRadius(8)
        // Make the entire cell invisible if it's a faded day
        .opacity(isFaded ? 0 : 1)
    }
}

fileprivate extension Date {
    func startOfDay(using calendar: Calendar) -> Date {
        calendar.startOfDay(for: self)
    }
}

fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    static var secondaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}


// MARK: - Mission Row View
struct MissionRowView: View {
    @ObservedObject var mission: Mission
    
    @EnvironmentObject var viewModel: MissionsViewModel

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
            
            if mission.status == .scheduled {
                scheduledSection
            } else {
                progressSection
                missionActionButtons
                    .padding(.top, 5)
            }

        }.padding(.vertical, 10)
    }
    
    @ViewBuilder
    private var scheduledSection: some View {
        if let scheduledDate = mission.scheduledDate {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    Text(countdown(to: scheduledDate, from: context.date))
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        VStack {
            if mission.isPomodoro && mission.status != .pending {
                VStack(spacing: 2) {
                    ProgressView(value: overallProgressValue, total: mission.totalDuration) {
                        HStack {
                            Text("Overall Mission Progress").font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(overallProgressValue / 60)) / \(Int(mission.totalDuration / 60)) min")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .tint(.blue)
                }
                .padding(.bottom, 8)
            }
            
            if mission.isPomodoro && mission.status == .inProgress {
                Text(mission.isBreakTime ? "Break Time!" : "Focus Cycle: \(mission.pomodoroCycle)")
                    .font(.headline).foregroundColor(mission.isBreakTime ? .green : .purple)
            }
            
            ProgressView(value: cycleProgressValue, total: cycleProgressTotal)
                .tint(mission.status == .inProgress ? (mission.isBreakTime ? .green : .purple) : .blue)
            
            HStack {
                Text(formatTime(mission.timeRemaining)).font(.system(size: 36, weight: .bold, design: .monospaced))
                Spacer()
                Text(formatTime(cycleProgressTotal)).font(.system(size: 18, weight: .semibold, design: .monospaced)).foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var missionActionButtons: some View {
        if mission.isEligibleForCycleBonus {
            VStack(alignment: .center, spacing: 10) {
                Text("Mission Goal Reached!")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.green)
                
                Text("Finish the current focus block for a +10% reward bonus.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                HStack {
                    Button("Complete Now") { viewModel.completeMission(mission: mission) }
                        .buttonStyle(.bordered).tint(.blue)
                    
                    Button("Focus for Bonus") { viewModel.acceptCycleBonus(mission: mission) }
                        .buttonStyle(.borderedProminent).tint(.purple)
                }
            }
            .frame(maxWidth: .infinity)
        } else {
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
                case .scheduled:
                     Text("Scheduled")
                        .font(.headline.bold())
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    private var cycleProgressValue: Double {
        let value = cycleProgressTotal - mission.timeRemaining
        return max(0, min(value, cycleProgressTotal))
    }
    
    private var cycleProgressTotal: Double {
        if mission.isPomodoro {
            return mission.isBreakTime ? viewModel.dailyMissionSettings.pomodoroBreakDuration : viewModel.dailyMissionSettings.pomodoroStudyDuration
        } else {
            return mission.totalDuration
        }
    }
    
    private var overallProgressValue: Double {
        guard mission.isPomodoro else { return 0 }
        
        let studyDuration = viewModel.dailyMissionSettings.pomodoroStudyDuration
        let completedCyclesTime = Double(mission.pomodoroCycle - 1) * studyDuration
        
        var currentCycleTime: Double = 0
        if !mission.isBreakTime && (mission.status == .inProgress || mission.status == .paused) {
            currentCycleTime = studyDuration - mission.timeRemaining
        }
        
        let value = completedCyclesTime + currentCycleTime
        
        return max(0, min(value, mission.totalDuration))
    }
    
    private func countdown(to date: Date, from now: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: now, to: date)
        
        let day = components.day ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let second = components.second ?? 0
        
        if day > 1 {
            return "Starts in \(day) days"
        } else if day == 1 {
            return "Starts tomorrow at \(date.formatted(date: .omitted, time: .shortened))"
        } else if hour > 0 {
            return String(format: "Starts in %dh %dm", hour, minute)
        } else if minute > 0 {
            return String(format: "Starts in %dm %ds", minute, second)
        } else if second > 0 {
            return "Starts in \(second)s"
        } else {
            return "Starting now..."
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        guard totalSeconds > 0 else { return "00:00" }
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
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
                
                Section {
                    pomodoroToggle
                    schedulingToggle
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
            .onChange(of: viewModel.missionHours) { _, _ in checkPomodoroEligibility() }
            .onChange(of: viewModel.missionMinutes) { _, _ in checkPomodoroEligibility() }
            .alert("Scheduling Conflict", isPresented: $viewModel.showConflictAlert, presenting: viewModel.conflictingMission) { conflictingMission in
                Button("Create Anyway", role: .destructive) {
                    viewModel.proceedWithMissionCreation()
                }
                Button("Cancel", role: .cancel) { }
            } message: { conflictingMission in
                Text("This mission overlaps with your scheduled mission \"\(conflictingMission.topicName)\". Are you sure you want to create it?")
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
        let totalMinutes = (viewModel.missionHours * 60) + viewModel.missionMinutes
        
        return Section {
            Picker("Study Type", selection: $viewModel.selectedStudyType) {
                Text("Select Study Type...").tag(nil as StudyType?)
                ForEach(viewModel.availableStudyTypes, id: \.self) { Text($0.displayString).tag($0 as StudyType?) }
            }.disabled(viewModel.selectedSubject == nil)
            
            HStack {
                Text("Duration")
                Spacer()
                Picker("Hours", selection: $viewModel.missionHours) { ForEach(0..<24) { Text("\($0) hr").tag($0) } }.pickerStyle(.menu)
                Picker("Minutes", selection: $viewModel.missionMinutes) { ForEach(0..<60) { Text("\($0) min").tag($0) } }.pickerStyle(.menu)
            }
        } header: {
            Text("Mission Details")
        } footer: {
            if totalMinutes < 5 {
                Text("Missions must be at least 5 minutes long.")
                    .foregroundColor(.red)
            }
        }
    }
    
    private var pomodoroToggle: some View {
        VStack(alignment: .leading, spacing: 5) {
            Toggle("Enable Pomodoro Mode", isOn: $viewModel.isPomodoroEnabled)
                .disabled(!viewModel.canEnablePomodoro)
            
            if !viewModel.canEnablePomodoro {
                Text(viewModel.pomodoroRequirementMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var schedulingToggle: some View {
        VStack {
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
    }
    
    private var createButtonSection: some View {
        let isTopicInvalid = viewModel.selectedSubject == nil || viewModel.selectedBranch == nil || viewModel.selectedTopic == nil || viewModel.selectedStudyType == nil
        
        let totalMinutes = (viewModel.missionHours * 60) + viewModel.missionMinutes
        let isDurationInvalid = totalMinutes < 5
        
        let isInvalid = isTopicInvalid || isDurationInvalid
        
        return Section {
            Button("Create Mission") {
                viewModel.createMission()
            }
            .disabled(isInvalid)
        }
    }
    
    private func checkPomodoroEligibility() {
        if !viewModel.canEnablePomodoro {
            viewModel.isPomodoroEnabled = false
        }
    }
}

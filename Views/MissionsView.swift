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
                VStack {
                    Picker("Planner View", selection: $viewModel.plannerViewType.animation()) {
                        ForEach(PlannerViewType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    switch viewModel.plannerViewType {
                    case .month:
                        MonthlyCalendarView(date: $viewModel.selectedDate)
                    case .week:
                        WeeklyCalendarView(date: $viewModel.selectedDate)
                    case .day:
                        DailyAgendaView(date: $viewModel.selectedDate)
                    }
                }
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
        }
        .sheet(item: $viewModel.missionToEdit) { mission in
            if let index = viewModel.activeMissions.firstIndex(where: { $0.id == mission.id }) {
                EditMissionView(mission: $viewModel.activeMissions[index])
            }
        }
        .sheet(item: $mainViewModel.missionToReview) { mission in
             MissionReviewView(
                 mission: mission,
                 missionToReview: $mainViewModel.missionToReview,
                 onReviewSubmit: { focus, understanding, challenge in
                     mainViewModel.submitMissionReview(for: mission, focus: focus, understanding: understanding, challenge: challenge)
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

// MARK: - Planner Views (Monthly, Weekly, Daily)

private struct CalendarDisplayEntry: Identifiable, Hashable {
    let id: String
    let date: Date
    let title: String
    let description: String
    let color: Color
    let iconName: String?
    let baseMission: Mission?

    init(mission: Mission) {
        self.id = mission.id.uuidString
        self.date = mission.scheduledDate ?? mission.creationDate
        self.title = mission.topicName
        self.baseMission = mission
        
        if mission.isBossBattle {
            self.description = mission.battleType?.rawValue ?? "Boss Battle"
            self.color = .red
            self.iconName = "crown.fill"
        } else {
            self.description = mission.branchName
            self.color = mission.source.color
            self.iconName = mission.source == .dungeon ? "shield.lefthalf.filled" : nil
        }
    }
    
    init(event: Event) {
        self.id = event.id
        self.date = event.startDate
        self.title = event.name
        self.description = "Special Event"
        self.color = .cyan
        self.iconName = "star.fill"
        self.baseMission = nil
    }
    
    var timeString: String {
        if baseMission == nil {
            return "All Day"
        } else {
            return date.formatted(date: .omitted, time: .shortened)
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: CalendarDisplayEntry, rhs: CalendarDisplayEntry) -> Bool {
        lhs.id == rhs.id
    }
}

struct DailyAgendaView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    @Binding var date: Date
    
    private var entries: [CalendarDisplayEntry] {
        let missions = viewModel.missions(for: date)
        let bosses = viewModel.bossBattles(for: date)
        let events = viewModel.events(for: date)
        
        let allEntries = missions.map(CalendarDisplayEntry.init) +
                         bosses.map(CalendarDisplayEntry.init) +
                         events.map(CalendarDisplayEntry.init)
        
        return allEntries.sorted(by: { $0.date < $1.date })
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(date.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.title2.bold())
                Spacer()
                Button(action: {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            
            if entries.isEmpty {
                 Spacer()
                 Text("No scheduled items for this day.")
                     .foregroundColor(.secondary)
                 Spacer()
            } else {
                List(entries) { entry in
                    Button(action: {
                        if let mission = entry.baseMission {
                            viewModel.missionToEdit = mission
                        }
                    }) {
                        HStack(spacing: 15) {
                            Text(entry.timeString)
                                .font(.subheadline.monospaced())
                                .frame(width: 80, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    if let icon = entry.iconName {
                                        Image(systemName: icon).foregroundColor(entry.color)
                                    }
                                    Text(entry.title)
                                        .font(.headline)
                                }
                                Text(entry.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(entry.color.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .disabled(entry.baseMission == nil)
                }
                .listStyle(.plain)
            }
        }
    }
}

struct WeeklyCalendarView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    @Binding var date: Date

    private var weekDays: [Date] {
        guard let weekInterval = Calendar.current.dateInterval(of: .weekOfYear, for: date) else { return [] }
        var days: [Date] = []
        for i in 0..<7 {
            if let day = Calendar.current.date(byAdding: .day, value: i, to: weekInterval.start) {
                days.append(day)
            }
        }
        return days
    }
    
    private var weekIntervalString: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let calendar = Calendar.current
        if calendar.isDate(first, equalTo: last, toGranularity: .month) {
            return "\(first.formatted(.dateTime.month().day())) - \(last.formatted(.dateTime.day()))"
        }
        return "\(first.formatted(.dateTime.month().day())) - \(last.formatted(.dateTime.month().day()))"
    }

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    date = Calendar.current.date(byAdding: .day, value: -7, to: date) ?? date
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                VStack {
                    Text(date.formatted(.dateTime.month(.wide).year()))
                        .font(.title2.bold())
                    Text(weekIntervalString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: {
                    date = Calendar.current.date(byAdding: .day, value: 7, to: date) ?? date
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()

            HStack(alignment: .top, spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    DayColumnView(day: day)
                        .onTapGesture {
                            viewModel.selectedDate = day
                            viewModel.plannerViewType = .day
                        }
                }
            }
            Spacer()
        }
    }
}

struct DayColumnView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    let day: Date
    
    private var isToday: Bool { Calendar.current.isDateInToday(day) }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(day.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.caption.bold())
                .foregroundColor(isToday ? .accentColor : .secondary)
            
            Text(day.formatted(.dateTime.day()))
                .font(.subheadline.bold())
                .padding(4)
                .background(isToday ? Color.accentColor : Color.clear)
                .foregroundColor(isToday ? .white : .primary)
                .clipShape(Circle())
            
            let missions = viewModel.missions(for: day)
            let bosses = viewModel.bossBattles(for: day)
            let events = viewModel.events(for: day)
            
            if !bosses.isEmpty {
                Circle().frame(width: 6, height: 6).foregroundColor(.red)
            }
            if !events.isEmpty {
                Circle().frame(width: 6, height: 6).foregroundColor(.cyan)
            }
            if !missions.isEmpty {
                 Circle().frame(width: 6, height: 6).foregroundColor(.blue)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(isToday ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}


struct MonthlyCalendarView: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    @State private var selectedEvent: Event?
    @Binding var date: Date
    
    private var days: [Date] {
        generateDaysInMonth(for: date)
    }
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
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

            let weekdaySymbols = calendar.shortWeekdaySymbols
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(days, id: \.self) { day in
                    CalendarDayCell(
                        day: day,
                        missions: viewModel.missions(for: day),
                        events: viewModel.events(for: day),
                        bossBattles: viewModel.bossBattles(for: day),
                        isFaded: !calendar.isDate(day, equalTo: date, toGranularity: .month),
                        onBackgroundTap: { date in
                            self.date = date
                            viewModel.plannerViewType = .day
                        },
                        onEventTap: { event in
                            self.selectedEvent = event
                        }
                    )
                }
            }
        }
        .background(Color.groupedBackground)
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event)
        }
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

// MARK: - New and Helper Views

struct EditMissionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: MissionsViewModel
    @EnvironmentObject var knowledgeTreeViewModel: KnowledgeTreeViewModel
    
    @Binding var mission: Mission
    
    @State private var scheduledDate: Date
    @State private var missionHours: Int
    @State private var missionMinutes: Int
    @State private var studyType: StudyType

    init(mission: Binding<Mission>) {
        self._mission = mission
        
        _scheduledDate = State(initialValue: mission.wrappedValue.scheduledDate ?? Date())
        let totalSeconds = mission.wrappedValue.totalDuration
        _missionHours = State(initialValue: Int(totalSeconds) / 3600)
        _missionMinutes = State(initialValue: (Int(totalSeconds) % 3600) / 60)
        _studyType = State(initialValue: mission.wrappedValue.studyType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Mission Details")) {
                    Text("Topic: \(mission.topicName)")
                        .foregroundColor(.secondary)
                    
                    let subjectCategory = knowledgeTreeViewModel.subjects.first { $0.name == mission.subjectName }?.category
                    let availableTypes = StudyType.allCases.filter { $0.categories.contains(subjectCategory ?? .stem) }
                    
                    Picker("Study Type", selection: $studyType) {
                        ForEach(availableTypes, id: \.self) { type in
                            Text(type.displayString).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Reschedule Mission")) {
                    DatePicker("New Scheduled Time", selection: $scheduledDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Adjust Duration")) {
                     HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Hours", selection: $missionHours) { ForEach(0..<24) { Text("\($0) hr").tag($0) } }.pickerStyle(.menu)
                        Picker("Minutes",selection: $missionMinutes) { ForEach(1..<60) { Text("\($0) min").tag($0) } }.pickerStyle(.menu)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        mission.scheduledDate = scheduledDate
                        let newDuration = TimeInterval((missionHours * 3600) + (missionMinutes * 60))
                        mission.totalDuration = newDuration
                        mission.timeRemaining = newDuration
                        mission.studyType = studyType
                        
                        dismiss()
                    }
                    .disabled(missionHours == 0 && missionMinutes < 5)
                }
            }
            .navigationTitle("Edit Mission")
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
}


struct EventDetailSheet: View {
    let event: Event
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Image(event.bannerImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()

                    Text(event.description)
                        .padding(.horizontal)

                    VStack(alignment: .leading) {
                        Text("Rewards").font(.headline)
                        ForEach(event.rewards) { reward in
                            HStack {
                                Image(reward.iconName)
                                    .resizable().scaledToFit().frame(width: 25, height: 25)
                                Text(reward.name)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondaryBackground)
                    .cornerRadius(10)
                    .padding(.horizontal)

                }
            }
            .navigationTitle(event.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct CalendarDayCell: View {
    @EnvironmentObject var viewModel: MissionsViewModel
    let day: Date
    let missions: [Mission]
    let events: [Event]
    let bossBattles: [Mission]
    let isFaded: Bool
    
    let onBackgroundTap: (Date) -> Void
    let onEventTap: (Event) -> Void
    
    private let calendar = Calendar.current
    private var isToday: Bool { calendar.isDateInToday(day) }
    
    private var dayComponents: DateComponents {
        calendar.dateComponents([.year, .month, .day], from: day)
    }
    private var weekday: Weekday? {
        Weekday(rawValue: calendar.component(.weekday, from: day))
    }
    private var isTicketUsed: Bool {
        viewModel.noStudyDays.contains(dayComponents)
    }
    private var canAffordTicket: Bool {
        (viewModel.mainViewModel?.player.gold ?? 0) >= 250
    }
    private var isStudyDay: Bool {
        guard let weekday = weekday else { return false }
        return viewModel.dailyMissionSettings.studyDays.contains(weekday)
    }
    private var isPastDate: Bool {
        calendar.startOfDay(for: day) < calendar.startOfDay(for: Date())
    }

    private func colorForMission(_ mission: Mission) -> Color {
        switch mission.source {
        case .manual:    return .blue.opacity(0.2)
        case .automatic: return .purple.opacity(0.2)
        case .guild:     return .green.opacity(0.2)
        case .dungeon:   return .orange.opacity(0.2)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !isFaded {
                Text(day.formatted(.dateTime.day()))
                    .font(.subheadline.weight(isToday ? .heavy : .regular))
                    .frame(width: 24, height: 24)
                    .background(isToday ? Color.accentColor : Color.clear)
                    .foregroundColor(isToday ? .white : .primary)
                    .clipShape(Circle())
                
                if isTicketUsed {
                    ticketView
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        scheduledItemsView
                        
                        let hasBlockingTasks = !missions.isEmpty || !bossBattles.isEmpty
                        if isStudyDay && !hasBlockingTasks && !isPastDate {
                            Spacer(minLength: 0)
                            suggestedStudyView
                        }
                    }
                }
                
            } else {
                Spacer()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
        .background(Color.secondaryBackground)
        .cornerRadius(8)
        .opacity(isFaded ? 0 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
             if !isFaded {
                onBackgroundTap(day)
            }
        }
        .contextMenu {
            if !isFaded && !isTicketUsed && !isPastDate {
                Button {
                    viewModel.useNoStudyDayTicket(for: day)
                } label: {
                    Label("Use No-Study Day Ticket", systemImage: "ticket.fill")
                }
                .disabled(!canAffordTicket)
            }
        }
    }
    
    private var ticketView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "ticket.fill")
                    .font(.largeTitle)
                    .foregroundColor(.green)
                Spacer()
            }
            Text("Day Off!")
                .font(.caption.bold())
                .foregroundColor(.green)
            Spacer()
        }
    }
    
    private var suggestedStudyView: some View {
        Button(action: {
            viewModel.scheduledDate = day
            viewModel.isShowingCreateSheet = true
        }) {
            VStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Suggested Study")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundColor(.secondary)
                .allowsHitTesting(false)
        )
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }
    
    private var scheduledItemsView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(bossBattles) { battle in
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill").foregroundColor(.yellow)
                        Text(battle.topicName).font(.caption2.bold()).lineLimit(1)
                    }
                    .padding(.vertical, 3).padding(.horizontal, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.3)).cornerRadius(4)
                }
                ForEach(events) { event in
                    Button(action: { onEventTap(event) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill").foregroundColor(.cyan)
                            Text(event.name).font(.caption2).lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain).padding(.vertical, 3).padding(.horizontal, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cyan.opacity(0.2)).cornerRadius(4)
                }
                ForEach(missions) { mission in
                    HStack(spacing: 4) {
                        if mission.source == .dungeon {
                            Image(systemName: "shield.lefthalf.filled").font(.caption2).foregroundColor(.orange)
                        }
                        Text(mission.topicName).font(.caption2).lineLimit(1)
                    }
                    .padding(.vertical, 3).padding(.horizontal, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(colorForMission(mission)).cornerRadius(4)
                }
            }
        }
    }
}


fileprivate extension MissionSource {
    var color: Color {
        switch self {
        case .manual:    return .blue
        case .automatic: return .purple
        case .guild:     return .green
        case .dungeon:   return .orange
        }
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
    @EnvironmentObject var knowledgeTreeViewModel: KnowledgeTreeViewModel
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
            .onAppear {
                if viewModel.scheduledDate != nil {
                    isScheduling = true
                }
            }
            .onChange(of: viewModel.missionHours) { _, _ in checkPomodoroEligibility() }
            .onChange(of: viewModel.missionMinutes) { _, _ in checkPomodoroEligibility() }
            .alert("Scheduling Conflict", isPresented: $viewModel.showConflictAlert, presenting: viewModel.conflictingMission) { conflictingMission in
                Button("Create Anyway", role: .destructive) {
                    viewModel.proceedWithMissionCreation(knowledgeTree: knowledgeTreeViewModel.subjects)
                }
                Button("Cancel", role: .cancel) { }
            } message: { conflictingMission in
                Text("This mission overlaps with your scheduled mission \"\(conflictingMission.topicName)\". Are you sure you want to create it?")
            }
        }
    }
    
    private var topicSection: some View {
        Section("Select Topic") {
            Picker("Subject", selection: $viewModel.selectedSubjectID) {
                Text("Select Subject...").tag(nil as UUID?)
                ForEach(knowledgeTreeViewModel.subjects) { Text($0.name).tag($0.id as UUID?) }
            }.onChange(of: viewModel.selectedSubjectID) {
                viewModel.selectedBranchID = nil
                viewModel.selectedStudyType = nil
            }
            
            Picker("Branch", selection: $viewModel.selectedBranchID) {
                Text("Select Branch...").tag(nil as UUID?)
                if let subjectID = viewModel.selectedSubjectID,
                   let subject = knowledgeTreeViewModel.subjects.first(where: { $0.id == subjectID }) {
                    ForEach(subject.branches.filter({ $0.isUnlocked })) { Text($0.name).tag($0.id as UUID?) }
                }
            }.disabled(viewModel.selectedSubjectID == nil)
             .onChange(of: viewModel.selectedBranchID) { viewModel.selectedTopicID = nil }
            
            Picker("Topic", selection: $viewModel.selectedTopicID) {
                Text("Select Topic...").tag(nil as UUID?)
                if let subjectID = viewModel.selectedSubjectID,
                   let subject = knowledgeTreeViewModel.subjects.first(where: { $0.id == subjectID }),
                   let branchID = viewModel.selectedBranchID,
                   let branch = subject.branches.first(where: { $0.id == branchID }) {
                    // --- THE FIX: Removed the incorrect filter ---
                    ForEach(branch.topics) { Text($0.name).tag($0.id as UUID?) }
                }
            }.disabled(viewModel.selectedBranchID == nil)
        }
    }
    
    private var detailsSection: some View {
        let totalMinutes = (viewModel.missionHours * 60) + viewModel.missionMinutes
        
        return Section {
            Picker("Study Type", selection: $viewModel.selectedStudyType) {
                Text("Select Study Type...").tag(nil as StudyType?)
                ForEach(viewModel.availableStudyTypes(from: knowledgeTreeViewModel.subjects), id: \.self) { Text($0.displayString).tag($0 as StudyType?) }
            }.disabled(viewModel.selectedSubjectID == nil)
            
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
        let isTopicInvalid = viewModel.selectedSubjectID == nil || viewModel.selectedBranchID == nil || viewModel.selectedTopicID == nil || viewModel.selectedStudyType == nil
        
        let totalMinutes = (viewModel.missionHours * 60) + viewModel.missionMinutes
        let isDurationInvalid = totalMinutes < 5
        
        let isInvalid = isTopicInvalid || isDurationInvalid
        
        return Section {
            Button("Create Mission") {
                viewModel.createMission(knowledgeTree: knowledgeTreeViewModel.subjects)
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

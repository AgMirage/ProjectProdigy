import SwiftUI

// MARK: - Main App View with TabBar
struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @StateObject private var missionsViewModel: MissionsViewModel
    // --- ADDED: The KnowledgeTreeViewModel is now a StateObject here to persist its state. ---
    @StateObject private var knowledgeTreeViewModel = KnowledgeTreeViewModel()

    init(player: Player) {
        let mainVM = MainViewModel(player: player)
        _viewModel = StateObject(wrappedValue: mainVM)
        _missionsViewModel = StateObject(wrappedValue: MissionsViewModel(mainViewModel: mainVM))
    }

    var body: some View {
        TabView {
            MainDashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            MissionsView()
                .tabItem { Label("Missions", systemImage: "list.bullet.clipboard.fill") }
            
            KnowledgeTreeView()
                .tabItem { Label("Knowledge", systemImage: "books.vertical.fill") }

            CommunityView()
                .tabItem { Label("Community", systemImage: "person.3.fill") }
            
            StoreView()
                .tabItem { Label("Store", systemImage: "cart.fill") }
            
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environmentObject(viewModel)
        .environmentObject(missionsViewModel)
        // --- ADDED: Inject the single instance of the viewModel into the environment. ---
        .environmentObject(knowledgeTreeViewModel)
        // --- ADDED: Initialize the knowledge tree when the main view appears. ---
        .onAppear {
            knowledgeTreeViewModel.reinitialize(with: viewModel)
        }
    }
}

// MARK: - Main Dashboard Screen
struct MainDashboardView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var missionsViewModel: MissionsViewModel // Access MissionsViewModel
    @State private var isShowingTitlesSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PlayerHeaderView( player: viewModel.player, onTap: { isShowingTitlesSheet = true })
                    
                    StatsGridView(stats: viewModel.player.stats)
                    
                    HStack(alignment: .bottom, spacing: 20) {
                        StreakView(streak: viewModel.player.checkInStreak)
                        FocusFamiliarView(familiar: viewModel.player.activeFamiliar)
                        VStack {
                            Text("Procrastination").font(.caption).bold()
                            Image("monster_stage_1").resizable().scaledToFit().frame(height: 60)
                                .scaleEffect(viewModel.procrastinationMonsterScale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.3), value: viewModel.procrastinationMonsterScale)
                        }
                        .padding().frame(maxWidth: .infinity).background(Color.secondaryBackground).cornerRadius(12)
                    }
                    
                    SystemLogView(logEntries: viewModel.systemLog)
                    
                    // --- NEW: Quick Mission Button ---
                    Button(action: {
                        missionsViewModel.generateQuickMission()
                    }) {
                        Label("Start Quick Mission", systemImage: "wand.and.stars")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .padding()
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .navigationTitle("Dashboard")
            .sheet(isPresented: $isShowingTitlesSheet) { TitlesView() }
        }
    }
}


// MARK: - (Existing Helper Views - Unchanged)
struct PlayerHeaderView: View {
    let player: Player
    let onTap: () -> Void
    var body: some View {
        HStack {
            NavigationLink(destination: AchievementsView(manager: MainViewModel(player: player).achievementManager)) {
                Image(player.currentAvatar.imageName).resizable().scaledToFit().frame(width: 60, height: 60).clipShape(Circle()).overlay(Circle().stroke(Color.gray, lineWidth: 2)).shadow(radius: 3)
            }
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.username).font(.title2).bold()
                    if let titleName = player.activeTitle?.name {
                        Text(titleName).font(.footnote).bold().foregroundColor(.purple)
                    } else {
                        Text("No Title Equipped").font(.footnote).italic().foregroundColor(.secondary)
                    }
                    Text(player.academicTier.rawValue).font(.subheadline).foregroundColor(.secondary)
                }
            }.buttonStyle(.plain)
            Spacer()
            HStack {
                Image("icon_gold_coin").resizable().scaledToFit().frame(width: 25, height: 25)
                Text("\(player.gold)").font(.title3).bold()
            }
        }.padding().background(Color.secondaryBackground).cornerRadius(12)
    }
}
struct FocusFamiliarView: View {
    let familiar: Familiar
    private var familiarImageName: String { return familiar.imageNamePrefix + "_stage_1" }
    var body: some View {
        VStack {
            Text(familiar.name).font(.caption).bold()
            Image(familiarImageName).resizable().scaledToFit().frame(height: 60)
            Text("Lvl: \(familiar.level)").font(.caption)
        }.padding().frame(maxWidth: .infinity).background(Color.secondaryBackground).cornerRadius(12)
    }
}
struct StatsGridView: View {
    let stats: Stats
    var body: some View {
        VStack {
            HStack { StatBubble(name: "INT", value: stats.intelligence, icon: "brain.head.profile"); StatBubble(name: "WIS", value: stats.wisdom, icon: "eyebrow"); StatBubble(name: "DEX", value: stats.dexterity, icon: "hand.draw.fill") }
            HStack { StatBubble(name: "CRE", value: stats.creativity, icon: "lightbulb.fill"); StatBubble(name: "STA", value: stats.stamina, icon: "bolt.heart.fill"); StatBubble(name: "FOC", value: stats.focus, icon: "scope") }
        }.padding().background(Color.secondaryBackground).cornerRadius(12)
    }
}
struct StatBubble: View {
    let name: String, value: Int, icon: String
    var body: some View {
        HStack {
            Image(systemName: icon).font(.caption).foregroundColor(.white).frame(width: 25, height: 25).background(Color.blue).clipShape(Circle())
            Text(name).font(.headline)
            Text("\(value)").font(.title2).bold().frame(minWidth: 40, alignment: .leading)
        }.frame(maxWidth: .infinity)
    }
}
struct StreakView: View {
    let streak: Int
    var body: some View {
        VStack {
            Image(systemName: "flame.fill").font(.system(size: 40)).foregroundColor(.orange)
            Text("\(streak) Day Streak").font(.headline).bold()
        }.padding().frame(maxWidth: .infinity).background(Color.secondaryBackground).cornerRadius(12)
    }
}

struct SystemLogView: View {
    let logEntries: [LogEntry]
    var body: some View {
        VStack(alignment: .leading) {
            Text("System Log").font(.headline).padding([.leading, .top])
            
            VStack(alignment: .leading, spacing: 5) {
                ForEach(logEntries) { entry in
                    HStack(alignment: .top) {
                        Text("[\(entry.timestamp, formatter: DateFormatter.logTimeFormatter)]")
                        Text(entry.message)
                    }
                    .font(.custom("Menlo", size: 12))
                    .foregroundColor(entry.color)
                }
            }
            .padding(10)
            .background(Color.black.opacity(0.9))
            .cornerRadius(8)
            
        }.padding(.top, 10)
    }
}
extension DateFormatter {
    static let logTimeFormatter: DateFormatter = { let formatter = DateFormatter(); formatter.dateFormat = "HH:mm:ss"; return formatter }()
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(player: Player(username: "Prodigy"))
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

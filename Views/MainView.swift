import SwiftUI

fileprivate enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case missions = "Missions"
    case knowledge = "Knowledge"
    case community = "Community"
    case store = "Store"
    case settings = "Settings"
    
    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .missions: return "list.bullet.clipboard.fill"
        case .knowledge: return "books.vertical.fill"
        case .community: return "person.3.fill"
        case .store: return "cart.fill"
        case .settings: return "gearshape.fill"
        }
    }
    var id: String { self.rawValue }
}

struct MainView: View {
    @StateObject private var viewModel: MainViewModel
    @StateObject private var missionsViewModel: MissionsViewModel
    @StateObject private var knowledgeTreeViewModel = KnowledgeTreeViewModel()
    
    @State private var selectedTab: AppTab = .home

    init(player: Player) {
        let mainVM = MainViewModel(player: player)
        _viewModel = StateObject(wrappedValue: mainVM)
        _missionsViewModel = StateObject(wrappedValue: MissionsViewModel(mainViewModel: mainVM))
    }

    var body: some View {
        Group {
            #if os(macOS)
            macOSRootView
            #else
            iOSTabView
            #endif
        }
        .environmentObject(viewModel)
        .environmentObject(missionsViewModel)
        .environmentObject(knowledgeTreeViewModel)
        .onAppear {
            // --- EDITED: Corrected the initializer call ---
            knowledgeTreeViewModel.reinitialize(with: viewModel)
            viewModel.knowledgeTreeViewModel = knowledgeTreeViewModel
        }
    }
    
    private var iOSTabView: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                viewFor(tab: tab)
                    .tabItem { Label(tab.rawValue, systemImage: tab.iconName) }
                    .tag(tab)
            }
        }
    }
    
    private var macOSRootView: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Select a view", selection: $selectedTab) {
                    ForEach(AppTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()

                ZStack {
                    viewFor(tab: .home).opacity(selectedTab == .home ? 1 : 0)
                    viewFor(tab: .missions).opacity(selectedTab == .missions ? 1 : 0)
                    viewFor(tab: .knowledge).opacity(selectedTab == .knowledge ? 1 : 0)
                    viewFor(tab: .community).opacity(selectedTab == .community ? 1 : 0)
                    viewFor(tab: .store).opacity(selectedTab == .store ? 1 : 0)
                    viewFor(tab: .settings).opacity(selectedTab == .settings ? 1 : 0)
                }
            }
        }
    }
    
    @ViewBuilder
    private func viewFor(tab: AppTab) -> some View {
        switch tab {
        case .home:
            MainDashboardView()
        case .missions:
            MissionsView()
        case .knowledge:
            KnowledgeTreeView()
        case .community:
            CommunityView()
        case .store:
            StoreView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Main Dashboard Screen
struct MainDashboardView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var missionsViewModel: MissionsViewModel
    @State private var isShowingTitlesSheet = false

    var body: some View {
        #if os(macOS)
        dashboardContent
        #else
        NavigationStack { dashboardContent }
        #endif
    }
    
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                PlayerHeaderView(
                    player: viewModel.player,
                    onAvatarTap: { viewModel.isShowingAvatarSelection = true },
                    onTitleTap: { isShowingTitlesSheet = true }
                )
                
                StatsGridView(stats: viewModel.player.stats)
                
                HStack(alignment: .bottom, spacing: 15) {
                    StreakView(streak: viewModel.player.checkInStreak)
                    
                    NavigationLink(destination: FamiliarDetailView(familiar: viewModel.player.activeFamiliar)) {
                        FocusFamiliarView(
                            familiar: viewModel.player.activeFamiliar,
                            onSwapTap: { viewModel.isShowingFamiliarSelection = true }
                        )
                    }
                    .buttonStyle(.plain)
                    
                    ProcrastinationMonsterView()
                }
                
                SystemLogView(logEntries: viewModel.systemLog)
                
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
                .disabled(!viewModel.isQuickMissionUnlocked)
                .overlay(
                    !viewModel.isQuickMissionUnlocked ?
                    Text("Complete \(10 - viewModel.player.completedMissionsCount) more missions to unlock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 50)
                    : nil
                )
            }
            .padding()
        }
        .background(Color.groupedBackground)
        .navigationTitle("Dashboard")
        .sheet(isPresented: $isShowingTitlesSheet) { TitlesView() }
        .sheet(isPresented: $viewModel.isShowingAvatarSelection) { AvatarSelectionView() }
        .sheet(isPresented: $viewModel.isShowingFamiliarSelection) { FamiliarSelectionView() }
    }
}

// MARK: - Helper Views
struct PlayerHeaderView: View {
    let player: Player
    let onAvatarTap: () -> Void
    let onTitleTap: () -> Void
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        HStack {
            Button(action: onAvatarTap) {
                Image(player.currentAvatar.imageName)
                    .resizable().scaledToFit().frame(width: 60, height: 60)
                    .clipShape(Circle()).overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    .shadow(radius: 3)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(player.username).font(.title2).bold()
                    NavigationLink(destination: AchievementsView(manager: mainViewModel.achievementManager)) {
                        Image(systemName: "trophy.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                
                Button(action: onTitleTap) {
                    if let titleName = player.activeTitle?.name {
                        Text(titleName).font(.footnote).bold().foregroundColor(.purple)
                    } else {
                        Text("No Title Equipped").font(.footnote).italic().foregroundColor(.secondary)
                    }
                }
                Text(player.academicTier.rawValue).font(.subheadline).foregroundColor(.secondary)
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
    let onSwapTap: () -> Void
    
    private var familiarImageName: String { return familiar.imageNamePrefix + "_stage_1" }
    
    var body: some View {
        VStack {
            HStack {
                Text(familiar.name).font(.caption).bold()
                Spacer()
                Button(action: onSwapTap) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .font(.caption)
                .buttonStyle(.borderless)
                .padding(.trailing, -5)
            }
            Image(familiarImageName).resizable().scaledToFit().frame(height: 60)
            HStack {
                Text("Lvl: \(familiar.level)")
                Spacer()
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(Int(familiar.happiness * 100))%")
            }
            .font(.caption)
        }.padding().frame(maxWidth: .infinity).background(Color.secondaryBackground).cornerRadius(12)
    }
}

struct ProcrastinationMonsterView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("Procrastination")
                .font(.caption).bold()
            
            VideoPlayerView(videoName: viewModel.monsterMood.videoName)
                .frame(height: 60)
                .scaleEffect(viewModel.procrastinationMonsterScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.3), value: viewModel.procrastinationMonsterScale)
            
            if let effect = viewModel.monsterMood.statusEffectDescription {
                Text(effect)
                    .font(.caption2)
                    .foregroundColor(viewModel.monsterMood.effectColor)
                    .multilineTextAlignment(.center)
            } else {
                Text("Feeling neutral.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Button(action: { viewModel.petTheMonster() }) {
                Text("Pat")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.gray)
            
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color.secondaryBackground)
        .cornerRadius(12)
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

fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.controlBackgroundColor)
    static var secondaryBackground = Color(NSColor.windowBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}

import SwiftUI

struct CommunityView: View {
    
    @EnvironmentObject var mainViewModel: MainViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Connect & Participate")) {
                    // Link to Guilds
                    NavigationLink(destination: GuildView(mainViewModel: mainViewModel)) {
                        HStack(spacing: 15) {
                            Image(systemName: "shield.lefthalf.filled")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.indigo)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("My Guild")
                                    .font(.headline)
                                Text("View your guild, members, and weekly mission.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Link to Events
                    NavigationLink(destination: EventsView()) {
                        HStack(spacing: 15) {
                            Image(systemName: "calendar.badge.star")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.cyan)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("Events")
                                    .font(.headline)
                                Text("Check for active and upcoming special events.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // --- NEW SECTION: Link to Stories ---
                    NavigationLink(destination: StoriesView(mainViewModel: mainViewModel)) {
                        HStack(spacing: 15) {
                            Image(systemName: "book.closed.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.orange)
                                .cornerRadius(8)
                            
                            VStack(alignment: .leading) {
                                Text("Story Library")
                                    .font(.headline)
                                Text("Unlock and read narrative chapters.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    // --- END NEW SECTION ---
                }
            }
            .navigationTitle("Community")
        }
    }
}

// MARK: - Preview
struct CommunityView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "Preview")
        let mainVM = MainViewModel(player: player)
        
        CommunityView()
            .environmentObject(mainVM)
    }
}

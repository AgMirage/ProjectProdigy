import SwiftUI

struct AchievementsView: View {
    
    @StateObject private var viewModel: AchievementsViewModel
    
    // The view now requires the manager to be passed to it upon creation.
    init(manager: AchievementManager) {
        _viewModel = StateObject(wrappedValue: AchievementsViewModel(manager: manager))
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(AchievementFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // List of Achievements
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.achievementsToDisplay) { achievement in
                            AchievementRowView(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
            .background(Color.groupedBackground)
        }
    }
}


// MARK: - Achievement Row View
struct AchievementRowView: View {
    let achievement: AchievementDisplayData
    
    var body: some View {
        HStack(spacing: 15) {
            Image(achievement.tierImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.headline)
                
                Text(descriptionText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic(achievement.isSecret && !achievement.isUnlocked)

                // Show progress bar only if not yet unlocked
                if !achievement.isUnlocked {
                    ProgressView(value: achievement.progress, total: achievement.goal)
                        .tint(.blue)
                } else {
                    // If unlocked, show the date
                    if let unlockedDate = achievement.unlockedDate {
                        Text("Unlocked: \(unlockedDate, formatter: DateFormatter.shortDate)")
                            .font(.caption)
                            .foregroundColor(.green)
                            .bold()
                    }
                }
            }
            
            Spacer()
            
            // Gold Reward
            HStack(spacing: 4) {
                Image("icon_gold_coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                Text("+\(achievement.goldReward)")
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding()
        // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
        .background(Color.secondaryBackground)
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 0.7 : 1.0)
        .saturation(achievement.isUnlocked ? 0.5 : 1.0)
    }
    
    /// Determines what to show for the description based on secret/unlocked status.
    private var descriptionText: String {
        if !achievement.isUnlocked && achievement.isSecret {
            return "???"
        }
        return achievement.description
    }
}

// MARK: - Date Formatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}


// MARK: - Preview
struct AchievementsView_Previews: PreviewProvider {
    static var previews: some View {
        // The preview now creates a dummy manager to pass to the view.
        AchievementsView(manager: AchievementManager())
    }
}


// MARK: - Cross-Platform Color Helpers (NEW)
fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    static var secondaryBackground = Color(NSColor.controlBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    static var secondaryBackground = Color(.secondarySystemGroupedBackground)
    #endif
}

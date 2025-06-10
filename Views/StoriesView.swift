//
//  StoriesView.swift
//  ProjectProdigy
//
//  Created by Kaia Quinn on 6/18/25.
//


import SwiftUI

// MARK: - Main Stories Library View
struct StoriesView: View {
    @StateObject private var viewModel: StoryViewModel
    
    init(mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: StoryViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 15) {
                    ForEach(viewModel.allStories) { story in
                        NavigationLink(destination: StoryReaderView(story: story)) {
                            StoryCardView(story: story, progress: viewModel.playerProgress[story.id])
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Story Library")
            // --- FIXED: Replaced iOS-specific color with a cross-platform one. ---
            .background(Color.groupedBackground)
            .alert(item: $viewModel.alertItem) { alert in
                Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
        .environmentObject(viewModel)
    }
}

// MARK: - Story Reader View
struct StoryReaderView: View {
    let story: Story
    @EnvironmentObject var viewModel: StoryViewModel
    @State private var sectionToShow: StorySection?

    var body: some View {
        List(story.sections) { section in
            SectionRowView(story: story, section: section, onRead: {
                sectionToShow = section
            })
        }
        .navigationTitle(story.title)
        .sheet(item: $sectionToShow) { section in
            StoryContentView(section: section)
        }
    }
}

// MARK: - Helper: StoryCardView
struct StoryCardView: View {
    let story: Story
    let progress: PlayerStoryProgress?
    
    private var completionPercentage: Double {
        guard let progress = progress, !story.sections.isEmpty else { return 0.0 }
        return Double(progress.unlockedSectionNumbers.count) / Double(story.sections.count)
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(story.bannerImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 180)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(story.title)
                    .font(.title2.bold())
                Text(story.description)
                    .font(.caption)
                ProgressView(value: completionPercentage)
                    .tint(.white)
                    .padding(.top, 5)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.5))
        }
        .cornerRadius(12)
        .clipped()
        .foregroundColor(.primary) // Ensure the link text color is appropriate
    }
}


// MARK: - Helper: SectionRowView
struct SectionRowView: View {
    let story: Story
    let section: StorySection
    let onRead: () -> Void
    @EnvironmentObject var viewModel: StoryViewModel
    
    var isUnlocked: Bool {
        viewModel.isSectionUnlocked(storyID: story.id, sectionNumber: section.sectionNumber)
    }
    
    var body: some View {
        HStack {
            Text("\(section.sectionNumber)")
                .font(.title2.bold())
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading) {
                Text(section.title)
                    .font(.headline)
                if !isUnlocked {
                    Text("Cost: \(section.goldCost) Gold")
                        .font(.caption)
                }
            }
            
            Spacer()
            
            if isUnlocked {
                Button("Read", action: onRead)
                    .buttonStyle(.bordered)
            } else {
                Button("Unlock") {
                    viewModel.unlockSection(story: story, section: section)
                }
                .buttonStyle(.borderedProminent)
                .disabled((viewModel.mainViewModel?.player.gold ?? 0) < section.goldCost)
            }
        }
        .padding(.vertical, 8)
        .opacity(isUnlocked ? 1.0 : 0.7)
    }
}

// MARK: - Helper: StoryContentView (Sheet)
struct StoryContentView: View {
    let section: StorySection
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(section.content)
                    .padding()
            }
            .navigationTitle(section.title)
            // --- FIXED: This modifier is unavailable on macOS, so we wrap it for iOS only. ---
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Previews
struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(mainViewModel: MainViewModel(player: Player(username: "Preview")))
    }
}


// MARK: - Cross-Platform Color Helpers (NEW)
fileprivate extension Color {
    #if os(macOS)
    static var groupedBackground = Color(NSColor.windowBackgroundColor)
    #else
    static var groupedBackground = Color(.systemGroupedBackground)
    #endif
}

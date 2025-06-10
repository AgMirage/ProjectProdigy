import SwiftUI

struct FountainView: View {
    
    @StateObject private var viewModel: FountainViewModel
    
    // The initializer now requires the MainViewModel to correctly set up
    // its own viewModel.
    init(mainViewModel: MainViewModel) {
        _viewModel = StateObject(wrappedValue: FountainViewModel(mainViewModel: mainViewModel))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // --- Result Display Area ---
            if let reward = viewModel.lastReward {
                GachaResultView(reward: reward)
                    .transition(.scale.combined(with: .opacity))
            } else {
                VStack {
                    Text("The Fountain of Knowledge")
                        .font(.title2).bold().foregroundColor(.secondary)
                    Text("Make a wish to receive a random reward.")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .frame(height: 150)
            }
            
            // --- Fountain Image ---
            Image("fountain_of_knowledge")
                .resizable().scaledToFit().frame(width: 200, height: 200)
                .rotationEffect(.degrees(viewModel.isPulling ? 360 : 0))
                .animation(
                    viewModel.isPulling ? .easeInOut(duration: 1.0).repeatForever(autoreverses: false) : .default,
                    value: viewModel.isPulling
                )
            
            Spacer()
            
            // --- Action Button ---
            Button(action: {
                withAnimation {
                    // This call is now much simpler.
                    viewModel.pullFromFountain()
                }
            }) {
                Text("Make a Wish (\(viewModel.pullCost) Gold)")
                    .font(.headline).bold().frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .padding()
            // The MainViewModel is now accessed through the environment for this check.
            .environmentObject(viewModel.mainViewModel!) // A temporary force unwrap for the button's check.
            .disabled(viewModel.isPulling || (viewModel.mainViewModel?.player.gold ?? 0) < viewModel.pullCost)
        }
        .alert(item: $viewModel.alertItem) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }
}

// MARK: - Helper View: GachaResultView
struct GachaResultView: View {
    let reward: GachaReward
    
    var body: some View {
        VStack {
            Text(reward.rarity.rawValue.uppercased())
                .font(.title.bold())
                .foregroundColor(reward.rarity.color)
                .padding(8)
                .background(reward.rarity.color.opacity(0.1))
                .cornerRadius(10)
            
            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundColor(reward.rarity.color)
            
            Text(reward.name)
                .font(.headline)
        }
        .padding()
        .frame(height: 150)
    }
}


// MARK: - Preview
struct FountainView_Previews: PreviewProvider {
    static var previews: some View {
        let mainVM = MainViewModel(player: Player(username: "GachaPreview"))
        mainVM.player.gold = 500
        
        // The preview now correctly initializes the view.
        return FountainView(mainViewModel: mainVM)
    }
}

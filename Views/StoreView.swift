import SwiftUI

struct StoreView: View {
    
    @StateObject private var viewModel = StoreViewModel()
    @EnvironmentObject var mainViewModel: MainViewModel

    var body: some View {
        NavigationStack {
            VStack {
                // The Picker now automatically includes the "Fountain" option from the enum.
                Picker("Category", selection: $viewModel.selectedCategory) {
                    ForEach(StoreItemCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // --- EDITED SECTION: Conditional Content ---
                if viewModel.selectedCategory == .fountain {
                    // If Fountain is selected, show the Gacha UI, passing in the MainViewModel.
                    FountainView(mainViewModel: mainViewModel)
                } else {
                    // Otherwise, show the normal list of items for sale.
                    List(viewModel.filteredItems) { item in
                        StoreItemRowView(item: item)
                    }
                    .listStyle(.plain)
                }
                // --- END EDITED SECTION ---
            }
            .navigationTitle("Item Store")
            .alert(item: $viewModel.purchaseAlert) { alertItem in
                Alert(
                    title: Text(alertItem.title),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// MARK: - Store Item Row View
struct StoreItemRowView: View {
    let item: StoreItem
    @EnvironmentObject var viewModel: StoreViewModel
    @EnvironmentObject var mainViewModel: MainViewModel

    var body: some View {
        HStack(spacing: 15) {
            Image(item.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(10)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: {
                viewModel.purchaseItem(item: item, player: &mainViewModel.player)
            }) {
                HStack(spacing: 4) {
                    Image("icon_gold_coin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                    Text("\(item.price)")
                        .bold()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.yellow.opacity(0.8))
            .foregroundColor(.black)
            .cornerRadius(20)
            .disabled(mainViewModel.player.gold < item.price)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        let player = Player(username: "StorePreview")
        let mainViewModel = MainViewModel(player: player)

        StoreView()
            .environmentObject(mainViewModel)
    }
}

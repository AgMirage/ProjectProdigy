import Foundation
import SwiftUI

// We define the structure for our alert data here.
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}


@MainActor
class StoreViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allItems: [StoreItem] = []
    @Published var selectedCategory: StoreItemCategory = .consumables
    @Published var purchaseAlert: AlertItem?
    
    // MARK: - Computed Properties
    
    var filteredItems: [StoreItem] {
        allItems.filter { $0.category == selectedCategory }
    }
    
    // MARK: - Initialization
    
    init() {
        loadItems()
    }
    
    
    // MARK: - Public Methods
    
    func purchaseItem(item: StoreItem, player: inout Player) {
        // 1. Check if the player can afford the item.
        guard player.gold >= item.price else {
            self.purchaseAlert = AlertItem(title: "Purchase Failed", message: "You do not have enough Gold to purchase the \(item.name).")
            return
        }
        
        // 2. The special requirement check for the potion has been removed.
        
        // 3. If all checks pass, deduct gold.
        player.gold -= item.price
        
        // 4. Apply the item's effect.
        if let effect = item.effect {
            // The .statRespecPotion case has been removed from the switch.
            switch effect {
            case .noStudyingDayTicket:
                print("Player bought a No-Study Day Ticket.")
                // In a real app: player.inventory.noStudyTickets += 1
            case .goldBooster25:
                print("Player bought a 25% Gold Booster.")
                // In a real app: player.activeBoosters.append(GoldBooster(multiplier: 1.25, duration: 86400))
            case .rerollMissionTicket:
                print("Player bought a Reroll Mission Ticket.")
                // In a real app: player.inventory.rerollTickets += 1
            }
        }
        
        // 5. Notify the user of the successful purchase.
        self.purchaseAlert = AlertItem(title: "Purchase Successful!", message: "You have successfully purchased the \(item.name) for \(item.price) Gold.")
    }
    
    
    // MARK: - Private Methods
    
    private func loadItems() {
        self.allItems = StoreInventory.allItems
    }
}

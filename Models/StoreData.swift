import Foundation

/// Defines the different categories of items available in the store.
enum StoreItemCategory: String, Codable, CaseIterable {
    case consumables = "Consumables"
    case themes = "Themes"
    case avatars = "Avatars"
    case rare = "Rare Items"
    case fountain = "Fountain"
}

/// Specifies the unique effect of a consumable item.
enum ConsumableEffect: String, Codable {
    case noStudyingDayTicket
    case goldBooster25
    case rerollMissionTicket
    // .statRespecPotion has been removed.
}

/// Represents a single item available for purchase in the Store.
struct StoreItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let price: Int
    let category: StoreItemCategory
    let iconName: String
    let effect: ConsumableEffect?
    
    init(id: UUID = UUID(), name: String, description: String, price: Int, category: StoreItemCategory, iconName: String, effect: ConsumableEffect? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.iconName = iconName
        self.effect = effect
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: StoreItem, rhs: StoreItem) -> Bool { lhs.id == rhs.id }
}


// MARK: - Store Inventory Data
struct StoreInventory {
    
    static let allItems: [StoreItem] = [
        
        // --- CONSUMABLES ---
        StoreItem(name: "No-Study Day Ticket",
                  description: "Preserves your Check-in Streak for one day without completing a mission. A life-saver!",
                  price: 250,
                  category: .consumables,
                  iconName: "item_ticket",
                  effect: .noStudyingDayTicket),
        
        StoreItem(name: "Gold Booster (25%)",
                  description: "Increases all Gold earned from missions by 25% for the next 24 hours.",
                  price: 500,
                  category: .consumables,
                  iconName: "item_gold_booster",
                  effect: .goldBooster25),
        
        StoreItem(name: "Reroll Mission Ticket",
                  description: "Allows you to receive a new set of Automatic Daily Missions for the day.",
                  price: 100,
                  category: .consumables,
                  iconName: "item_reroll_ticket",
                  effect: .rerollMissionTicket),
        
        // --- RARE ITEMS ---
        // The Stat Respec Potion has been deleted from this list.
        // You could add other rare, non-consumable items here in the future.
    ]
}

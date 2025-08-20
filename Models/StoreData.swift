import Foundation

/// Defines the different categories of items available in the store.
enum StoreItemCategory: String, Codable, CaseIterable {
    case consumables = "Consumables"
    case themes = "Themes"
    case avatars = "Avatars"
    case wallpapers = "Wallpapers"
    case rare = "Rare Items"
    case fountain = "Fountain"
}

/// Specifies the unique effect of a consumable item.
enum ConsumableEffect: String, Codable {
    case noStudyingDayTicket
    case goldBooster25
    case rerollMissionTicket
    // --- NEW ---
    case procrastinationRepellent
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
    let videoName: String? // Add this line

    init(id: UUID = UUID(), name: String, description: String, price: Int, category: StoreItemCategory, iconName: String, effect: ConsumableEffect? = nil, videoName: String? = nil) { // Add videoName here
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.iconName = iconName
        self.effect = effect
        self.videoName = videoName // And here
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
                  iconName: "item_NoStudyDay_ticket",
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
        
        // --- NEW ---
        StoreItem(name: "Procrastination Repellent",
                  description: "Freezes the Procrastination Monster's progress for 24 hours.",
                  price: 300,
                  category: .consumables,
                  iconName: "item_procrastination_repellent",
                  effect: .procrastinationRepellent),
        
        // --- THEMES ---
        StoreItem(name: "Arcane Library Theme",
                  description: "A theme with warm wood textures, glowing runes, and a serif font.",
                  price: 5000,
                  category: .themes,
                  iconName: "theme_arcane_library"),
        // --- END NEW ---

        // --- AVATARS ---
        StoreItem(name: "Academic Scroll Avatar",
                  description: "A studious-looking avatar with a warm glow.",
                  price: 1500,
                  category: .avatars,
                  iconName: "Avatar_feminine_academic_scroll_warmglow_lightskin"),
        
        StoreItem(name: "Formal Book Avatar",
                  description: "A formally dressed avatar with a blue light.",
                  price: 1500,
                  category: .avatars,
                  iconName: "Avatar_feminine_formal_book_bluelight_lightskin"),
        
        StoreItem(name: "Classic Scholar Owl Avatar",
                  description: "A classic scholar with a wise owl companion.",
                  price: 2000,
                  category: .avatars,
                  iconName: "Avatar_masculine_classic_scholar_owl_lightskin"),
        
        StoreItem(name: "Glasses Scholar Globe Avatar",
                  description: "A scholar with glasses and a holographic globe.",
                  price: 2000,
                  category: .avatars,
                  iconName: "Avatar_feminine_glasses_scholar_darkskin_globe"),
        
        StoreItem(name: "Formal Glasses Library Avatar",
                  description: "A formal avatar in a grand library setting.",
                  price: 2000,
                  category: .avatars,
                  iconName: "Avatar_masculine_glasses_formal_darkskin_library"),
                  
        // --- WALLPAPERS ---
        StoreItem(name: "Urban Loft",
                  description: "A cozy urban loft to set a relaxing mood.",
                  price: 3000,
                  category: .wallpapers,
                  iconName: "wallpaper_cafe",
                  videoName: "UrbanLoft"),

        // --- RARE ITEMS ---
    ]
}

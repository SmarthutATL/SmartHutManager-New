import SwiftUI
import CoreData

enum InventoryFilter: String, CaseIterable {
    case all = "All Items"
    case inWarehouse = "In Warehouse"
    case assignedToTradesmen = "Assigned to Tradesmen"
}

class InventoryViewModel: ObservableObject {
    @Published var inventoryItems: [Inventory] = []
    @Published var tradesmen: [Tradesmen] = []
    @Published var categories: [String] = [] // List of unique inventory categories
    @Published var selectedFilter: InventoryFilter = .all // Current filter for inventory view

    private var context: NSManagedObjectContext

    // Initialize with the CoreData context
    init(context: NSManagedObjectContext) {
        self.context = context
        loadInventoryItems()
        loadTradesmen()
        loadCategories()
    }

    // Computed property to calculate warehouse inventory count
    var warehouseInventoryCount: Int {
        inventoryItems.filter { $0.tradesmen == nil }.reduce(0) { $0 + Int($1.quantity) }
    }

    // Computed property to filter inventory based on selected filter
    var filteredInventory: [Inventory] {
        switch selectedFilter {
        case .all:
            return inventoryItems
        case .inWarehouse:
            return inventoryItems.filter { $0.tradesmen == nil }
        case .assignedToTradesmen:
            return inventoryItems.filter { $0.tradesmen != nil }
        }
    }

    // Fetch inventory items from CoreData
    func loadInventoryItems() {
        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        do {
            inventoryItems = try context.fetch(fetchRequest)
            for item in inventoryItems {
                print("Loaded Item: \(item.name ?? ""), Category: \(item.inventoryCategory ?? "None")")
            }
        } catch {
            print("Failed to fetch inventory items: \(error.localizedDescription)")
        }
    }

    // Fetch tradesmen from CoreData
    func loadTradesmen() {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        do {
            tradesmen = try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch tradesmen: \(error.localizedDescription)")
        }
    }

    // Fetch unique inventory categories
    func loadCategories() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Inventory.fetchRequest()
        fetchRequest.propertiesToFetch = ["inventoryCategory"]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.resultType = .dictionaryResultType

        do {
            if let results = try context.fetch(fetchRequest) as? [[String: Any]] {
                categories = results.compactMap { $0["inventoryCategory"] as? String }.sorted()
            }
        } catch {
            print("Failed to fetch categories: \(error.localizedDescription)")
        }
    }

    // Add a new inventory item
    func saveNewItem(name: String, price: Double, quantity: Int16, category: String) {
        let newItem = Inventory(context: context)
        newItem.name = name
        newItem.price = price
        newItem.quantity = quantity
        newItem.inventoryCategory = category

        saveContext()
    }

    // Assign inventory item to a tradesman
    func assignItemToTradesman(item: Inventory, tradesman: Tradesmen, quantity: Int16) {
        guard let itemName = item.name else {
            print("Item name is nil, assignment aborted.")
            return
        }

        guard item.quantity >= quantity else {
            print("Not enough stock of \(itemName) to assign \(quantity). Current stock: \(item.quantity).")
            return
        }

        guard quantity > 0 else {
            print("Invalid quantity (\(quantity)) for assignment.")
            return
        }

        // Deduct the assigned quantity from the warehouse stock
        item.quantity -= quantity

        // Create a new Inventory record for the tradesman
        let assignedItem = Inventory(context: context)
        assignedItem.name = item.name
        assignedItem.price = item.price
        assignedItem.quantity = quantity
        assignedItem.tradesmen = tradesman
        assignedItem.inventoryCategory = item.inventoryCategory

        saveContext()
        print("Assigned \(quantity) of \(itemName) to \(tradesman.name ?? "Unknown Tradesman").")
    }

    // Update an existing inventory item
    func updateItem(_ item: Inventory, name: String, price: Double, quantity: Int16, category: String) {
        item.name = name
        item.price = price
        item.quantity = quantity
        item.inventoryCategory = category

        saveContext()
    }

    // Delete an inventory item
    func deleteItem(_ item: Inventory) {
        context.delete(item)
        saveContext()
    }

    // Get inventory by tradesman
    func getInventoryForTradesman(_ tradesman: Tradesmen) -> [Inventory] {
        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tradesmen == %@", tradesman)

        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch inventory for tradesman: \(error.localizedDescription)")
            return []
        }
    }

    // Save changes to CoreData
    private func saveContext() {
        do {
            try context.save()
            loadInventoryItems() // Refresh the list after saving
            loadCategories() // Refresh categories
        } catch {
            print("Failed to save changes to inventory: \(error.localizedDescription)")
        }
    }
}

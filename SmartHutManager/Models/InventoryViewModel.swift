import SwiftUI
import CoreData

class InventoryViewModel: ObservableObject {
    @Published var inventoryItems: [Inventory] = []
    @Published var tradesmen: [Tradesmen] = []
    private var context: NSManagedObjectContext

    // Initialize with the CoreData context
    init(context: NSManagedObjectContext) {
        self.context = context
        loadInventoryItems()
        loadTradesmen()
    }

    // Computed property to calculate warehouse inventory count
    var warehouseInventoryCount: Int {
        inventoryItems.filter { $0.tradesmen == nil }.reduce(0) { $0 + Int($1.quantity) }
    }

    // Fetch inventory items from CoreData
    func loadInventoryItems() {
        let fetchRequest: NSFetchRequest<Inventory> = Inventory.fetchRequest()
        do {
            inventoryItems = try context.fetch(fetchRequest)
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

    // Add a new inventory item
    func saveNewItem(name: String, price: Double, quantity: Int16) {
        let newItem = Inventory(context: context)
        newItem.name = name
        newItem.price = price
        newItem.quantity = quantity

        saveContext()
    }

    // Assign inventory item to a tradesman
    func assignItemToTradesman(item: Inventory, tradesman: Tradesmen, quantity: Int16) {
        guard item.quantity >= quantity else {
            print("Not enough stock to assign.")
            return
        }

        item.quantity -= quantity

        let assignedItem = Inventory(context: context)
        assignedItem.name = item.name
        assignedItem.price = item.price
        assignedItem.quantity = quantity
        assignedItem.tradesmen = tradesman

        saveContext()
    }

    // Update an existing inventory item
    func updateItem(_ item: Inventory, name: String, price: Double, quantity: Int16) {
        item.name = name
        item.price = price
        item.quantity = quantity

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
        } catch {
            print("Failed to save changes to inventory: \(error.localizedDescription)")
        }
    }
}

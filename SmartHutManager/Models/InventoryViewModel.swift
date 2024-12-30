import SwiftUI
import CoreData

class InventoryViewModel: ObservableObject {
    @Published var inventoryItems: [Inventory] = []
    private var context: NSManagedObjectContext

    // Initialize with the CoreData context
    init(context: NSManagedObjectContext) {
        self.context = context
        loadInventoryItems()
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

    // Add a new inventory item
    func saveNewItem(name: String, price: Double, quantity: Int16) {
        let newItem = Inventory(context: context)
        newItem.name = name
        newItem.price = price
        newItem.quantity = quantity

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

import SwiftUI
import CoreData

struct RecentlyDeletedItemsView: View {
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager // Access shared manager
    @Environment(\.managedObjectContext) private var viewContext // Access Core Data context

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if !invoices.isEmpty {
                        categoryCard(
                            title: "Deleted Invoices",
                            items: invoices,
                            color: .blue,
                            restoreAction: restoreItem,
                            deleteAction: deleteItem
                        )
                    }
                    
                    if !workOrders.isEmpty {
                        categoryCard(
                            title: "Deleted Work Orders",
                            items: workOrders,
                            color: .orange,
                            restoreAction: restoreItem,
                            deleteAction: deleteItem
                        )
                    }

                    if !customers.isEmpty {
                        categoryCard(
                            title: "Deleted Customers",
                            items: customers,
                            color: .green,
                            restoreAction: restoreItem,
                            deleteAction: deleteItem
                        )
                    }

                    // Placeholder if no items are present
                    if deletedItemsManager.recentlyDeletedItems.isEmpty {
                        Text("No recently deleted items.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationTitle("Recently Deleted")
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    // Computed Properties for Filtering
    private var invoices: [DeletedItem] {
        deletedItemsManager.recentlyDeletedItems.filter { $0.type == .invoice }
    }

    private var workOrders: [DeletedItem] {
        deletedItemsManager.recentlyDeletedItems.filter { $0.type == .workOrder }
    }

    private var customers: [DeletedItem] {
        deletedItemsManager.recentlyDeletedItems.filter { $0.type == .customer }
    }

    // Category Card
    @ViewBuilder
    private func categoryCard(
        title: String,
        items: [DeletedItem],
        color: Color,
        restoreAction: @escaping (DeletedItem) -> Void,
        deleteAction: @escaping (DeletedItem) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)

            ForEach(items) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(color)
                        .frame(width: 32, height: 32)
                    
                    Text(item.description)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()

                    // Restore Button
                    Button(action: { restoreAction(item) }) {
                        Text("Restore")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(8)
                            .background(Capsule().stroke(Color.green, lineWidth: 1))
                    }

                    // Delete Button
                    Button(action: { deleteAction(item) }) {
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Capsule().stroke(Color.red, lineWidth: 1))
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .padding(.bottom, 16)
    }

    // MARK: - Actions
    private func restoreItem(_ item: DeletedItem) {
        switch item.type {
        case .invoice:
            print("Restored invoice: \(item.description)") // Add invoice restoration logic if needed
        case .workOrder:
            restoreWorkOrder(from: item) // Pass the complete DeletedItem to the restoreWorkOrder function
        case .customer:
            restoreCustomer(description: item.description)
        case .message:
            print("Restored message: \(item.description)") // Handle other types
        }

        // Remove item from deletedItemsManager
        deletedItemsManager.removeDeletedItem(withId: item.id)
    }

    private func restoreCustomer(description: String) {
        // Create a new Customer object in Core Data
        let newCustomer = Customer(context: viewContext)
        newCustomer.name = description // Use the description as the name (adjust as needed)

        do {
            try viewContext.save()
            print("Customer \(description) restored successfully.")
        } catch {
            print("Failed to restore customer: \(error.localizedDescription)")
        }
    }

    private func restoreWorkOrder(from deletedItem: DeletedItem) {
        // Ensure the deleted item is of type workOrder
        guard deletedItem.type == .workOrder else { return }

        // Create a new WorkOrder object in Core Data
        let restoredWorkOrder = WorkOrder(context: viewContext)
        restoredWorkOrder.workOrderNumber = Int16(deletedItem.description.split(separator: "#").last?.trimmingCharacters(in: .whitespaces) ?? "") ?? 0
        restoredWorkOrder.date = deletedItem.originalDate ?? Date() // Use original date or set to now
        restoredWorkOrder.status = deletedItem.originalStatus ?? "open" // Use original status or default to "open"
        restoredWorkOrder.category = deletedItem.originalCategory // Restore category if available

        // Restore associated customer
        if let customerName = deletedItem.originalCustomerName {
            let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name == %@", customerName)

            if let customer = (try? viewContext.fetch(fetchRequest))?.first {
                restoredWorkOrder.customer = customer // Link to existing customer
            } else {
                // Create a new customer if it doesn't exist
                let newCustomer = Customer(context: viewContext)
                newCustomer.name = customerName
                restoredWorkOrder.customer = newCustomer
            }
        }

        // Restore associated tradesmen
        if let tradesmenNames = deletedItem.originalTradesmen {
            for name in tradesmenNames {
                let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", name)

                if let tradesman = (try? viewContext.fetch(fetchRequest))?.first {
                    restoredWorkOrder.addToTradesmen(tradesman) // Link to existing tradesman
                } else {
                    // Create a new tradesman if it doesn't exist
                    let newTradesman = Tradesmen(context: viewContext)
                    newTradesman.name = name
                    restoredWorkOrder.addToTradesmen(newTradesman)
                }
            }
        }

        // Save the restored work order to Core Data
        do {
            try viewContext.save()
            print("Work order \(restoredWorkOrder.workOrderNumber) restored successfully.")
        } catch {
            print("Failed to restore work order: \(error.localizedDescription)")
        }
    }
    
    private func deleteItem(_ item: DeletedItem) {
        // Permanently remove the item
        deletedItemsManager.removeDeletedItem(withId: item.id)
        print("Permanently deleted: \(item.description)")
    }
}

import SwiftUI
import CoreData

struct EditThresholdsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Inventory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Inventory.name, ascending: true)],
        predicate: NSPredicate(format: "tradesmen == nil") // Filter items without tradesmen
    ) private var inventoryItems: FetchedResults<Inventory>

    var body: some View {
        NavigationView {
            List {
                ForEach(inventoryItems) { item in
                    InventoryThresholdRow(item: item)
                }
            }
            .navigationTitle("Set Stock Thresholds")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
}

struct InventoryThresholdRow: View {
    @ObservedObject var item: Inventory

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.name ?? "Unknown Item")
                .font(.headline)
            HStack {
                TextField("Low Stock", value: $item.lowStockThreshold, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("High Stock", value: $item.highStockThreshold, format: .number)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding(.vertical, 8)
    }
}

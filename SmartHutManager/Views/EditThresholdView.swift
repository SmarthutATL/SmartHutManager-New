import SwiftUI
import CoreData

struct EditThresholdsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Inventory.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Inventory.name, ascending: true)],
        predicate: NSPredicate(format: "tradesmen == nil") // Filter items without tradesmen
    ) private var inventoryItems: FetchedResults<Inventory>
    
    @State private var showInfo = false // State to toggle the explanation section

    var body: some View {
        NavigationView {
            VStack {
                // Info Section Toggle
                infoSection

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(inventoryItems) { item in
                            InventoryThresholdCard(item: item)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
            .navigationTitle("Edit Stock Thresholds")
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

    // MARK: - Info Section
    private var infoSection: some View {
        VStack {
            HStack {
                Text("What do these fields mean?")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    withAnimation {
                        showInfo.toggle()
                    }
                }) {
                    Image(systemName: showInfo ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            if showInfo {
                VStack(alignment: .leading, spacing: 8) {
                    explanationRow(
                        title: "Low Stock Threshold",
                        description: "When the quantity of an item reaches this number or lower, you'll receive an alert and it will be marked as 'Low Stock' in the Inventory Overview."
                    )
                    explanationRow(
                        title: "High Stock Threshold",
                        description: "This value helps you keep track of surplus inventory. Items with quantities higher than this value can be filtered as 'High Stock' in the Inventory Overview."
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    private func explanationRow(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Inventory Threshold Card
struct InventoryThresholdCard: View {
    @ObservedObject var item: Inventory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item Name
            Text(item.name ?? "Unknown Item")
                .font(.headline)
                .foregroundColor(.primary)

            // Input Fields with Descriptions
            VStack(spacing: 8) {
                HStack {
                    Text("Low Stock Threshold:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("Enter a number", value: $item.lowStockThreshold, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }

                HStack {
                    Text("High Stock Threshold:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("Enter a number", value: $item.highStockThreshold, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .padding()
    }
}

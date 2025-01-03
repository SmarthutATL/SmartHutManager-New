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
            VStack(spacing: 0) {
                // Info Section Toggle
                infoSection
                
                // Inventory List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(inventoryItems) { item in
                            InventoryThresholdRow(item: item) // Compact row design
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                
                // Sticky Save Button
                saveButton
            }
            .navigationTitle("Edit Stock Thresholds")
        }
    }

    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveChanges) {
            Text("Save Changes")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
                .shadow(radius: 2)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
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
                        description: "Receive alerts when stock falls to this level."
                    )
                    explanationRow(
                        title: "High Stock Threshold",
                        description: "Monitor surplus stock with this value."
                    )
                }
                .padding(12)
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

// MARK: - Inventory Threshold Row
struct InventoryThresholdRow: View {
    @ObservedObject var item: Inventory

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                // Item Name
                Text(item.name ?? "Unknown Item")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Compact Fields in a Single Row
            HStack(spacing: 16) {
                thresholdField(title: "Low Stock:", value: $item.lowStockThreshold)
                thresholdField(title: "High Stock:", value: $item.highStockThreshold)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
        .padding(.horizontal)
    }

    private func thresholdField(title: String, value: Binding<Int16>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField("Enter", value: value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 60)
        }
    }
}

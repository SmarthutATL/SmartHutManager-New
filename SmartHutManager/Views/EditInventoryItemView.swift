import SwiftUI
import CoreData

struct EditInventoryItemView: View {
    @ObservedObject var item: Inventory
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var name: String = ""
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var selectedCategory: String = ""
    @State private var suggestedCategories: [String] = []
    @State private var showSuggestions: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    // Name Field
                    TextField("Name", text: $name)
                        .onChange(of: name) { newValue in
                            updateCategorySuggestions(for: newValue)
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Price Field
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    // Quantity Field
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                // Category Section
                Section(header: Text("Category")) {
                    VStack(alignment: .leading) {
                        TextField("Category", text: $selectedCategory)
                            .onTapGesture {
                                showSuggestions = true
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        if showSuggestions && !suggestedCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(suggestedCategories, id: \.self) { suggestion in
                                    Button(action: {
                                        selectedCategory = suggestion
                                        showSuggestions = false
                                    }) {
                                        Text(suggestion)
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 2)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle()) // Makes the entire button area tappable
                                    }
                                    .buttonStyle(BorderlessButtonStyle()) // Prevents button conflicts
                                }
                            }
                            .padding(.top, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadItemDetails()
            }
        }
    }

    // MARK: - Load Item Details
    private func loadItemDetails() {
        name = item.name ?? ""
        price = String(item.price)
        quantity = String(item.quantity)
        selectedCategory = item.inventoryCategory ?? ""
        updateCategorySuggestions(for: name)
    }

    // MARK: - Save Changes
    private func saveChanges() {
        item.name = name
        item.price = Double(price) ?? 0.0
        item.quantity = Int16(quantity) ?? 0
        item.inventoryCategory = selectedCategory

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to save changes: \(error)")
        }
    }

    // MARK: - Category Suggestions
    private func updateCategorySuggestions(for itemName: String) {
        suggestedCategories = generateCategorySuggestions(for: itemName)
        showSuggestions = !suggestedCategories.isEmpty
    }

    private func generateCategorySuggestions(for itemName: String) -> [String] {
        let lowercasedName = itemName.lowercased()

        var suggestions: [String] = []

        // Electrical and Smart Home
        if lowercasedName.contains("wire") || lowercasedName.contains("cable") || lowercasedName.contains("electrical tape") || lowercasedName.contains("outlet") || lowercasedName.contains("adapter") || lowercasedName.contains("charger") {
            suggestions.append("Electrical")
        }
        if lowercasedName.contains("zip tie") || lowercasedName.contains("screw") || lowercasedName.contains("bolt") || lowercasedName.contains("tool") || lowercasedName.contains("drill") {
            suggestions.append("Hardware & Tools")
        }
        if lowercasedName.contains("led") || lowercasedName.contains("light") || lowercasedName.contains("dimmer") || lowercasedName.contains("switch") || lowercasedName.contains("fixture") || lowercasedName.contains("bulb") {
            suggestions.append("Lighting & Electrical")
        }
        if lowercasedName.contains("ring doorbell") || lowercasedName.contains("google nest") || lowercasedName.contains("smart") || lowercasedName.contains("thermostat") || lowercasedName.contains("camera") || lowercasedName.contains("sensor") {
            suggestions.append("Smart Home Devices")
        }

        // Painting and Supplies
        if lowercasedName.contains("paint") || lowercasedName.contains("roller") || lowercasedName.contains("brush") || lowercasedName.contains("tray") || lowercasedName.contains("drop cloth") {
            suggestions.append("Painting Supplies")
        }

        // Hardware and Tools
        if lowercasedName.contains("screw") || lowercasedName.contains("bolt") || lowercasedName.contains("nut") || lowercasedName.contains("drill") || lowercasedName.contains("tool") || lowercasedName.contains("wrench") || lowercasedName.contains("saw") || lowercasedName.contains("handle") || lowercasedName.contains("hinge") || lowercasedName.contains("level") {
            suggestions.append("Hardware & Tools")
        }

        // Plumbing
        if lowercasedName.contains("pipe") || lowercasedName.contains("valve") || lowercasedName.contains("plumbing") || lowercasedName.contains("fitting") || lowercasedName.contains("hose") || lowercasedName.contains("faucet") || lowercasedName.contains("sink") || lowercasedName.contains("drain") || lowercasedName.contains("coupling") {
            suggestions.append("Plumbing Supplies")
        }

        // TV & Mounts
        if lowercasedName.contains("tv") || lowercasedName.contains("mount") || lowercasedName.contains("apple tv") || lowercasedName.contains("remote") || lowercasedName.contains("bracket") || lowercasedName.contains("hdmi") || lowercasedName.contains("monitor") {
            suggestions.append("TV & Accessories")
        }

        // Doors and Security
        if lowercasedName.contains("door") || lowercasedName.contains("handle") || lowercasedName.contains("lock") || lowercasedName.contains("deadbolt") || lowercasedName.contains("hinge") || lowercasedName.contains("knob") || lowercasedName.contains("security") || lowercasedName.contains("peephole") {
            suggestions.append("Doors & Security")
        }

        // Miscellaneous Office Supplies
        if lowercasedName.contains("stapler") || lowercasedName.contains("pen") || lowercasedName.contains("notebook") || lowercasedName.contains("paper") || lowercasedName.contains("binder") || lowercasedName.contains("clip") {
            suggestions.append("Office Supplies")
        }

        // Automotive
        if lowercasedName.contains("tire") || lowercasedName.contains("battery") || lowercasedName.contains("oil") || lowercasedName.contains("filter") || lowercasedName.contains("toolbox") {
            suggestions.append("Automotive Supplies")
        }

        // Fallback
        if suggestions.isEmpty {
            suggestions.append("Miscellaneous")
        }

        return suggestions
    }
}

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
        
        // Split the input name into individual words for broader matching
        let words = lowercasedName.split(separator: " ").map { String($0) }
        
        // Electrical and Smart Home
        if words.contains(where: { $0.contains("wire") || $0.contains("cable") || $0.contains("electrical") || $0.contains("outlet") || $0.contains("adapter") || $0.contains("charger") }) {
            suggestions.append("Electrical")
        }
        if words.contains(where: { $0.contains("zip") || $0.contains("screw") || $0.contains("bolt") || $0.contains("tool") || $0.contains("drill") }) {
            suggestions.append("Hardware & Tools")
        }
        if words.contains(where: { $0.contains("led") || $0.contains("light") || $0.contains("dimmer") || $0.contains("switch") || $0.contains("fixture") || $0.contains("bulb") }) {
            suggestions.append("Lighting & Electrical")
        }
        if words.contains(where: { $0.contains("ring") || $0.contains("doorbell") || $0.contains("nest") || $0.contains("smart") || $0.contains("thermostat") || $0.contains("camera") || $0.contains("sensor") }) {
            suggestions.append("Smart Home Devices")
        }
        
        // Painting and Supplies
        if words.contains(where: { $0.contains("paint") || $0.contains("roller") || $0.contains("brush") || $0.contains("tray") || $0.contains("drop") }) {
            suggestions.append("Painting Supplies")
        }
        
        // Drywall and Supplies
        if words.contains(where: { $0.contains("drywall") ||
            $0.contains("putty") ||
            $0.contains("joint") ||
            $0.contains("compound") ||
            $0.contains("ready-mixed") ||
            $0.contains("purpose") ||
            $0.contains("sheetrock") }) {
            suggestions.append("Drywall & Supplies")
        }
        
        // Hardware and Tools
        if words.contains(where: { $0.contains("screw") || $0.contains("bolt") || $0.contains("nut") || $0.contains("drill") || $0.contains("tool") || $0.contains("wrench") || $0.contains("saw") || $0.contains("handle") || $0.contains("hinge") || $0.contains("level") }) {
            suggestions.append("Hardware & Tools")
        }
        
        // Plumbing
        if words.contains(where: { $0.contains("pipe") || $0.contains("valve") || $0.contains("plumbing") || $0.contains("fitting") || $0.contains("hose") || $0.contains("faucet") || $0.contains("sink") || $0.contains("drain") || $0.contains("coupling") }) {
            suggestions.append("Plumbing Supplies")
        }
        
        // TV & Mounts
        if words.contains(where: { $0.contains("tv") || $0.contains("mount") || $0.contains("remote") || $0.contains("bracket") || $0.contains("hdmi") || $0.contains("monitor") }) {
            suggestions.append("TV & Accessories")
        }
        
        // Doors and Security
        if words.contains(where: { $0.contains("door") || $0.contains("handle") || $0.contains("lock") || $0.contains("deadbolt") || $0.contains("hinge") || $0.contains("knob") || $0.contains("security") || $0.contains("peephole") }) {
            suggestions.append("Doors & Security")
        }
        
        // Miscellaneous Office Supplies
        if words.contains(where: { $0.contains("stapler") || $0.contains("pen") || $0.contains("notebook") || $0.contains("paper") || $0.contains("binder") || $0.contains("clip") }) {
            suggestions.append("Office Supplies")
        }
        
        // Automotive
        if words.contains(where: { $0.contains("tire") || $0.contains("battery") || $0.contains("oil") || $0.contains("filter") || $0.contains("toolbox") }) {
            suggestions.append("Automotive Supplies")
        }
        
        // Fallback
        if suggestions.isEmpty {
            suggestions.append("Miscellaneous")
        }
        
        return suggestions
    }
}

import SwiftUI

struct AddNewItemView: View {
    @Binding var isAddingNewItem: Bool
    var onSave: (String, Double, Int16, String) -> Void // Includes category
    
    @SceneStorage("addItemName") private var name: String = ""
    @SceneStorage("addItemPrice") private var price: String = ""
    @SceneStorage("addItemQuantity") private var quantity: String = ""
    @SceneStorage("addItemCategory") private var category: String = ""
    
    @State private var nameError: String? = nil
    @State private var priceError: String? = nil
    @State private var quantityError: String? = nil
    @State private var categoryError: String? = nil
    
    @State private var suggestedCategories: [String] = [] // Dynamic category suggestions
    @State private var showSuggestions: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item Details")) {
                    // Item Name Field
                    LabeledTextField(
                        title: "Item Name",
                        placeholder: "Enter item name",
                        text: $name,
                        errorMessage: $nameError
                    )
                    .onChange(of: name) { newValue in
                        updateCategorySuggestions(for: newValue)
                    }
                    
                    // Price Field
                    LabeledTextField(
                        title: "Price",
                        placeholder: "Enter item price (e.g., 10.99)",
                        text: $price,
                        errorMessage: $priceError
                    )
                    .keyboardType(.decimalPad)
                    
                    // Quantity Field
                    LabeledTextField(
                        title: "Quantity",
                        placeholder: "Enter item quantity",
                        text: $quantity,
                        errorMessage: $quantityError
                    )
                    .keyboardType(.numberPad)
                    
                    // Category Field with Suggestions
                    VStack(alignment: .leading) {
                        LabeledTextField(
                            title: "Category",
                            placeholder: "Enter or select a category",
                            text: $category,
                            errorMessage: $categoryError
                        )
                        .onTapGesture {
                            showSuggestions = !suggestedCategories.isEmpty
                        }
                        
                        if showSuggestions && !suggestedCategories.isEmpty {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(suggestedCategories, id: \.self) { suggestion in
                                    Button(action: {
                                        category = suggestion // Correctly update the category
                                        showSuggestions = false // Hide suggestions after selection
                                    }) {
                                        Text(suggestion)
                                            .foregroundColor(.blue)
                                            .padding(.vertical, 2)
                                            .frame(maxWidth: .infinity, alignment: .leading) // Ensure buttons don't overlap
                                            .contentShape(Rectangle()) // Make the whole button tappable
                                    }
                                    .buttonStyle(BorderlessButtonStyle()) // Prevent button conflicts
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
                
                Section {
                    // Save Button
                    Button(action: {
                        validateAndSave()
                        clearSceneStorage() // Clear stored values after saving
                    }) {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid())
                }
            }
            .navigationTitle("Add New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddingNewItem = false
                        clearSceneStorage() // Clear stored values after canceling
                    }
                }
            }
        }
    }
    
    // MARK: - Validation
    private func validateName() -> String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Item name cannot be empty."
        }
        return nil
    }
    
    private func clearSceneStorage() {
        name = ""
        price = ""
        quantity = ""
        category = ""
    }
    
    private func validatePrice() -> String? {
        guard let value = Double(price), value > 0 else {
            return "Price must be a valid number greater than 0."
        }
        return nil
    }
    
    private func validateQuantity() -> String? {
        guard let value = Int(quantity), value > 0 else {
            return "Quantity must be a valid number greater than 0."
        }
        return nil
    }
    
    private func validateCategory() -> String? {
        if category.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Category cannot be empty."
        }
        return nil
    }
    
    private func isFormValid() -> Bool {
        return validateName() == nil &&
        validatePrice() == nil &&
        validateQuantity() == nil &&
        validateCategory() == nil
    }
    
    private func validateAndSave() {
        nameError = validateName()
        priceError = validatePrice()
        quantityError = validateQuantity()
        categoryError = validateCategory()
        
        if isFormValid() {
            guard let priceValue = Double(price), let quantityValue = Int16(quantity) else { return }
            onSave(name, priceValue, quantityValue, category)
            isAddingNewItem = false
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


// MARK: - LabeledTextField
struct LabeledTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    @Binding var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .onChange(of: text) { newValue in
                    errorMessage = validateText(newValue)
                    print("\(title) updated to: \(newValue). Error: \(errorMessage ?? "None")")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            errorMessage == nil ? Color.clear : Color.red,
                            lineWidth: 1
                        )
                )
                .disableAutocorrection(true)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 5)
    }

    private func validateText(_ text: String) -> String? {
        return text.trimmingCharacters(in: .whitespaces).isEmpty ? "\(title) cannot be empty." : nil
    }
}

// MARK: - LabeledCurrencyField for Price Input
struct LabeledCurrencyField: View {
    var title: String
    var placeholder: String
    @Binding var value: Double
    @Binding var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField(
                placeholder,
                value: $value,
                format: .number.precision(.fractionLength(2))
            )
            .onChange(of: value) { newValue in
                errorMessage = validateValue(newValue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
            .keyboardType(.decimalPad)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        errorMessage == nil ? Color.clear : Color.red,
                        lineWidth: 1
                    )
            )

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 5)
    }

    private func validateValue(_ value: Double) -> String? {
        return value <= 0 ? "\(title) must be greater than 0." : nil
    }
}

// MARK: - LabeledNumericField for Quantity Input
struct LabeledNumericField: View {
    var title: String
    var placeholder: String
    @Binding var value: Int
    @Binding var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField(
                placeholder,
                value: $value,
                format: .number
            )
            .onChange(of: value) { newValue in
                errorMessage = validateValue(newValue)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.secondarySystemBackground))
            )
            .keyboardType(.numberPad)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        errorMessage == nil ? Color.clear : Color.red,
                        lineWidth: 1
                    )
            )
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func validateValue(_ value: Int) -> String? {
        return value <= 0 ? "\(title) must be greater than 0." : nil
    }
}


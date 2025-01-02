import SwiftUI

struct AddNewItemView: View {
    @Binding var isAddingNewItem: Bool
    var onSave: (String, Double, Int16, String) -> Void // Includes category
    
    @State private var name: String = ""
    @State private var price: String = ""
    @State private var quantity: String = ""
    @State private var category: String = "" // Category field
    
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
        
        // Electrical and Smart Home
        if lowercasedName.contains("wire") || lowercasedName.contains("cable") || lowercasedName.contains("zip tie") || lowercasedName.contains("electrical tape") || lowercasedName.contains("outlet") || lowercasedName.contains("adapter") || lowercasedName.contains("charger") {
            suggestions.append("Electrical")
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

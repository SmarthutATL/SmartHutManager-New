import SwiftUI

struct AddNewItemView: View {
    @Binding var isAddingNewItem: Bool
    var onSave: (String, Double, Int16) -> Void

    @State private var name: String = ""
    @State private var price: String = ""
    @State private var quantity: String = ""

    @State private var nameError: String? = nil
    @State private var priceError: String? = nil
    @State private var quantityError: String? = nil

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
                }

                Section {
                    // Save Button
                    Button(action: {
                        print("Save button pressed. Starting validation...")
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
                        print("Cancel button pressed. Closing AddNewItemView.")
                        isAddingNewItem = false
                    }
                }
            }
        }
    }

    // MARK: - Validation
    private func validateName() -> String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            print("Validation Error: Name is empty.")
            return "Item name cannot be empty."
        }
        print("Name validated successfully: \(name)")
        return nil
    }

    private func validatePrice() -> String? {
        guard let value = Double(price), value > 0 else {
            print("Validation Error: Invalid price - \(price)")
            return "Price must be a valid number greater than 0."
        }
        print("Price validated successfully: \(value)")
        return nil
    }

    private func validateQuantity() -> String? {
        guard let value = Int(quantity), value > 0 else {
            print("Validation Error: Invalid quantity - \(quantity)")
            return "Quantity must be a valid number greater than 0."
        }
        print("Quantity validated successfully: \(value)")
        return nil
    }

    private func isFormValid() -> Bool {
        let isValid = validateName() == nil && validatePrice() == nil && validateQuantity() == nil
        print("Form validation status: \(isValid ? "Valid" : "Invalid")")
        return isValid
    }

    private func validateAndSave() {
        // Perform validation
        nameError = validateName()
        priceError = validatePrice()
        quantityError = validateQuantity()

        // If all fields are valid, save the item
        if nameError == nil, priceError == nil, quantityError == nil {
            print("All fields are valid. Preparing to save item...")
            guard let priceValue = Double(price), let quantityValue = Int16(quantity) else {
                print("Failed to convert price or quantity to required types.")
                return
            }
            print("Saving item with details: Name = \(name), Price = \(priceValue), Quantity = \(quantityValue)")
            onSave(name, priceValue, quantityValue)
            print("Item saved successfully. Closing AddNewItemView.")
            isAddingNewItem = false
        } else {
            print("Validation failed. Errors: NameError = \(nameError ?? "None"), PriceError = \(priceError ?? "None"), QuantityError = \(quantityError ?? "None")")
        }
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

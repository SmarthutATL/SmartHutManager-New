import SwiftUI

struct AddNewItemView: View {
    @Binding var newItem: Material
    @Binding var isAddingNewItem: Bool
    var onSave: () -> Void // Callback when the user saves the item

    // Validation error messages
    @State private var nameError: String? = nil
    @State private var priceError: String? = nil
    @State private var quantityError: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Item Details")) {
                    // Name Field
                    LabeledTextField(
                        title: "Item Name",
                        placeholder: "Enter item name",
                        text: $newItem.name,
                        errorMessage: $nameError
                    )
                    .onChange(of: newItem.name) { _ in validateName() }

                    // Price Field
                    LabeledNumericField(
                        title: "Price",
                        placeholder: "Enter item price",
                        value: $newItem.price,
                        errorMessage: $priceError
                    )
                    .keyboardType(.decimalPad)
                    .onChange(of: newItem.price) { _ in validatePrice() }

                    // Quantity Field
                    LabeledNumericField(
                        title: "Quantity",
                        placeholder: "Enter item quantity",
                        value: Binding(
                            get: { Double(newItem.quantity) },
                            set: { newItem.quantity = Int($0) }
                        ),
                        errorMessage: $quantityError
                    )
                    .keyboardType(.numberPad)
                    .onChange(of: newItem.quantity) { _ in validateQuantity() }
                }

                Section {
                    HStack {
                        Button(action: resetForm) {
                            Text("Reset")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }

                        Button(action: saveItem) {
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
            }
            .navigationTitle("Add New Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isAddingNewItem = false // Close the sheet
                    }
                }
            }
        }
    }

    // MARK: - Form Validation Methods
    private func validateName() {
        nameError = newItem.name.isEmpty ? "Item name cannot be empty" : nil
    }

    private func validatePrice() {
        priceError = newItem.price <= 0 ? "Price must be greater than 0" : nil
    }

    private func validateQuantity() {
        quantityError = newItem.quantity <= 0 ? "Quantity must be greater than 0" : nil
    }

    private func isFormValid() -> Bool {
        validateName()
        validatePrice()
        validateQuantity()
        return nameError == nil && priceError == nil && quantityError == nil
    }

    // MARK: - Save Action
    private func saveItem() {
        if isFormValid() {
            print("Saving Item: \(newItem)")
            onSave()
            isAddingNewItem = false // Close the sheet
        } else {
            print("Form contains errors")
        }
    }

    // MARK: - Reset Action
    private func resetForm() {
        newItem = Material(name: "", price: 0.0, quantity: 0)
        nameError = nil
        priceError = nil
        quantityError = nil
    }
}

// MARK: - LabeledTextField for Text Input
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
                .padding(.horizontal)
                .frame(height: 44)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    VStack {
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    },
                    alignment: .bottomLeading
                )
        }
        .padding(.vertical, 5)
    }
}

// MARK: - LabeledNumericField for Numeric Input
struct LabeledNumericField: View {
    var title: String
    var placeholder: String
    @Binding var value: Double
    @Binding var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField(placeholder, value: $value, format: .number)
                .padding(.horizontal)
                .frame(height: 44)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .keyboardType(.decimalPad)
                .overlay(
                    VStack {
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    },
                    alignment: .bottomLeading
                )
        }
        .padding(.vertical, 5)
    }
}

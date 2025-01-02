import SwiftUI

struct AssignInventoryView: View {
    var item: Inventory
    var tradesmen: [Tradesmen]
    var onAssign: (Tradesmen, Int16) -> Void

    @State private var selectedTradesman: Tradesmen? = nil
    @State private var quantityToAssign: Int16 = 1
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Item Details
            VStack(alignment: .leading, spacing: 8) {
                Text("Assign Item")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)

                Text(item.name ?? "Unknown")
                    .font(.headline)
                Text("Price: $\(item.price, specifier: "%.2f")")
                Text("Available Quantity: \(item.quantity)")
            }
            .padding()

            Divider()

            // Assign to Tradesman
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Tradesman")
                    .font(.headline)

                Picker("Tradesman", selection: $selectedTradesman) {
                    Text("None").tag(nil as Tradesmen?)
                    ForEach(tradesmen, id: \.self) { tradesman in
                        Text(tradesman.name ?? "Unknown")
                            .tag(tradesman as Tradesmen?)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .padding()

            Divider()

            // Quantity to Assign
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Quantity")
                    .font(.headline)

                Stepper(value: $quantityToAssign, in: 1...item.quantity) {
                    Text("Quantity: \(quantityToAssign)")
                        .font(.subheadline)
                }
            }
            .padding()

            Spacer()

            // Action Buttons
            HStack {
                Button(action: {
                    dismiss() // Cancel
                }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    if let tradesman = selectedTradesman {
                        onAssign(tradesman, quantityToAssign)
                        dismiss() // Confirm and Dismiss
                    }
                }) {
                    Text("Assign")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedTradesman == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(selectedTradesman == nil)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

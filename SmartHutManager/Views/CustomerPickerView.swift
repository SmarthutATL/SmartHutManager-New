import SwiftUI

struct CustomerPickerView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default)
    private var customers: FetchedResults<Customer>
    
    @Binding var selectedCustomer: Customer?
    @Environment(\.presentationMode) var presentationMode // To dismiss the view

    var body: some View {
        NavigationView {
            List(customers) { customer in
                Button(action: {
                    selectedCustomer = customer
                    presentationMode.wrappedValue.dismiss() // Dismiss after selection
                }) {
                    HStack {
                        Text(customer.name ?? "Unknown")
                            .foregroundColor(selectedCustomer == customer ? .blue : .primary)
                        if selectedCustomer == customer {
                            Spacer()
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Customer")
        }
    }
}

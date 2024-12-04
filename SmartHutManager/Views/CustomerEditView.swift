import SwiftUI

struct CustomerEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var customer: Customer
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var address: String
    
    // Initialize state variables from the customer data
    init(customer: Customer) {
        _name = State(initialValue: customer.name ?? "")
        _phoneNumber = State(initialValue: customer.phoneNumber ?? "")
        _email = State(initialValue: customer.email ?? "")
        _address = State(initialValue: customer.address ?? "")
        self.customer = customer
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Customer Info")) {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                    TextField("Email", text: $email)
                    TextField("Address", text: $address)
                }
            }
            .navigationBarTitle("Edit Customer", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveCustomerDetails()
                }
            )
        }
    }
    
    // Save the updated customer details
    private func saveCustomerDetails() {
        customer.name = name
        customer.phoneNumber = phoneNumber
        customer.email = email
        customer.address = address
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Failed to save customer details: \(error.localizedDescription)")
        }
    }
}

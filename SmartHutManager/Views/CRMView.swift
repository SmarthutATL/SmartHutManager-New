import SwiftUI

struct CRMView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // State to manage search query
    @State private var searchText = ""
    @State private var showingAddCustomerView = false

    // Fetch request to retrieve customers from Core Data
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var customers: FetchedResults<Customer>
    
    
    // Filtered customers based on search query, sorted by last name
    var filteredCustomers: [(Customer, String?)] {
        // Sorting by last name here instead of relying on FetchRequest sorting
        let sortedCustomers = customers.sorted { first, second in
            let firstLastName = first.lastName
            let secondLastName = second.lastName
            return firstLastName.localizedCaseInsensitiveCompare(secondLastName) == .orderedAscending
        }
        
        // Apply search filtering
        if searchText.isEmpty {
            return sortedCustomers.map { ($0, nil) }
        } else {
            return sortedCustomers.compactMap { customer in
                if let name = customer.name, name.localizedCaseInsensitiveContains(searchText) {
                    return (customer, nil)
                } else if let phone = customer.phoneNumber, phone.localizedCaseInsensitiveContains(searchText) {
                    return (customer, "Match found in: phone number")
                } else if let address = customer.address, address.localizedCaseInsensitiveContains(searchText) {
                    return (customer, "Match found in: address")
                } else {
                    return nil
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    TextField("Search by name, phone, or address", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    Button(action: {
                        showingAddCustomerView.toggle()
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .padding(.trailing)
                    }
                }

                // Customer list
                List {
                    ForEach(filteredCustomers, id: \.0.objectID) { (customer, matchInfo) in
                        NavigationLink(destination: CustomerDetailView(customer: customer)) {
                            VStack(alignment: .leading) {
                                Text(customer.name ?? "Unknown")
                                
                                // Conditionally show match info if available (i.e., not from name)
                                if let matchInfo = matchInfo {
                                    Text(matchInfo)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteCustomers)
                }
            }
            .navigationTitle("Customers")
            .sheet(isPresented: $showingAddCustomerView) {
                AddCustomerView(onCustomerCreated: { newCustomer in
                    addNewCustomerToCRM(newCustomer)
                })
            }
        }
    }

    // Function to add the new customer to the CRM
    private func addNewCustomerToCRM(_ customer: Customer) {
        showingAddCustomerView = false
    }

    // Function to delete a customer
    private func deleteCustomers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let customer = filteredCustomers[index].0 // Get the customer from the filtered list
                if let customerToDelete = customers.first(where: { $0.objectID == customer.objectID }) {
                    viewContext.delete(customerToDelete)
                }
            }

            do {
                try viewContext.save()
            } catch {
                print("Failed to delete customer: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Customer Last Name Computed Property
extension Customer {
    var lastName: String {
        // Split the name by spaces, remove any empty components, and take all components after the first one as the "last name".
        let nameComponents = name?.components(separatedBy: " ").filter { !$0.isEmpty } ?? []
        
        // If there's only one component, return it as the last name (single-word name). Otherwise, return all components except the first as the "last name."
        let lastNameComponents = nameComponents.dropFirst().joined(separator: " ")
        
        return lastNameComponents.isEmpty ? nameComponents.first ?? "" : lastNameComponents
    }
}

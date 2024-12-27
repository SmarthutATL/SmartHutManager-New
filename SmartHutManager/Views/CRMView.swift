import SwiftUI

struct CRMView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // State for search query and add customer view
    @State private var searchText = ""
    @State private var showingAddCustomerView = false

    // Fetch customers from Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.name, ascending: true)],
        animation: .default
    ) private var customers: FetchedResults<Customer>
    
    // Grouped customers based on the search query
    private var groupedCustomers: [String: [Customer]] {
        let filtered = customers.filter { customer in
            searchText.isEmpty ||
            customer.name?.localizedCaseInsensitiveContains(searchText) == true ||
            customer.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true ||
            customer.address?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        return Dictionary(grouping: filtered) { customer in
            String(customer.name?.prefix(1).uppercased() ?? "#")
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Header with search bar
                    headerView
                    
                    // Grouped customer list
                    List {
                        ForEach(groupedCustomers.keys.sorted(), id: \.self) { key in
                            Section(header: Text(key).font(.headline)) {
                                ForEach(groupedCustomers[key] ?? [], id: \.objectID) { customer in
                                    NavigationLink(destination: CustomerDetailView(customer: customer)) {
                                        customerRow(for: customer)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteCustomers(from: groupedCustomers[key] ?? [], offsets: offsets)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
                .navigationTitle("Customers")
                .padding(.top, -10) // Reduce the top padding slightly
                
                // Floating Add Customer Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddCustomerView.toggle()
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .sheet(isPresented: $showingAddCustomerView) {
                AddCustomerView { newCustomer in
                    addNewCustomer(newCustomer)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            TextField("Search by name, phone, or address", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Customer Row View
    private func customerRow(for customer: Customer) -> some View {
        Text(customer.name ?? "Unknown")
            .font(.body)
            .fontWeight(.medium)
            .padding(.vertical, 4)
    }

    // MARK: - Add Customer Logic
    private func addNewCustomer(_ customer: Customer) {
        withAnimation {
            viewContext.insert(customer)
            saveContext()
            showingAddCustomerView = false
        }
    }
    
    // MARK: - Delete Customers Logic
    private func deleteCustomers(from group: [Customer], offsets: IndexSet) {
        withAnimation {
            offsets.map { group[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
}

// MARK: - Customer Last Name Computed Property
extension Customer {
    var lastName: String {
        let nameComponents = name?.components(separatedBy: " ").filter { !$0.isEmpty } ?? []
        let lastNameComponents = nameComponents.dropFirst().joined(separator: " ")
        return lastNameComponents.isEmpty ? nameComponents.first ?? "" : lastNameComponents
    }
}

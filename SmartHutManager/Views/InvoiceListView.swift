import SwiftUI
import CoreData

struct InvoiceListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch all invoices from Core Data
    @FetchRequest(
        entity: Invoice.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: false)]
    ) var invoices: FetchedResults<Invoice>
    
    @State private var searchQuery: String = "" // Search bar input
    @State private var sortOption: InvoiceSortOption = .date(ascending: false) // Default sorting option
    @State private var selectedJobCategory: String? = nil // Track selected job category for filtering
    @State private var selectedPaidStatus: String? = nil // Track selected paid status for filtering
    @State private var showingActionSheet = false // Single action sheet state
    @State private var actionSheetType: ActionSheetType = .none // Track which action sheet is showing
    
    // Enum to track which action sheet to show
    enum ActionSheetType {
        case category
        case paidStatus
        case none
    }
    
    // List of job categories
    let jobCategories = [
        "Accent Wall", "Camera Installation", "Drywall Repair", "Electrical", "Furniture Assembly",
        "General Handyman", "Home Theater Installation", "Lighting", "Painting", "Picture Hanging",
        "Plumbing", "Pressure Washing", "TV Mounting"
    ]
    
    // List of statuses for invoices
    let paidStatuses = ["Paid", "Unpaid"]
    
    // Calculate the total amount owed from unpaid invoices
    private var totalAmountOwed: Double {
        invoices
            .filter { $0.status == "Unpaid" }
            .reduce(0) { $0 + $1.computedTotalAmount }
    }
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar and Filter/Sort Buttons
                HStack {
                    TextField("Search by customer, address, or phone", text: $searchQuery)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // Sort Menu
                    Menu {
                        Button(action: {
                            toggleDateSort()
                        }) { Text("Sort by Date (\(sortOption.isDateAscending ? "Newest" : "Oldest") First)") }
                        Button(action: {
                            sortOption = .amount(ascending: true)
                        }) { Text("Sort by Amount (Lowest to Highest)") }
                        Button(action: {
                            sortOption = .amount(ascending: false)
                        }) { Text("Sort by Amount (Highest to Lowest)") }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                            .font(.title2)
                    }
                    .padding(.trailing, 8)
                    
                    // Filter Menu
                    Menu {
                        Button(action: {
                            actionSheetType = .paidStatus
                            showingActionSheet = true
                        }) {
                            Text("Filter by Paid Status")
                        }

                        Button(action: {
                            actionSheetType = .category
                            showingActionSheet = true
                        }) {
                            Text("Filter by Category")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
                            .font(.title2)
                    }
                    .padding(.trailing, 8)
                }
                .padding([.horizontal, .top])
                
                // Paid Status Filter Info
                if let selectedPaidStatus = selectedPaidStatus {
                    HStack {
                        Text("Filtering by Status: \(selectedPaidStatus)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button(action: {
                            self.selectedPaidStatus = nil // Clear paid status filter
                        }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Job Category Filter Info
                if let selectedJobCategory = selectedJobCategory {
                    HStack {
                        Text("Filtering by Category: \(selectedJobCategory)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button(action: {
                            self.selectedJobCategory = nil // Clear category filter
                        }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Filtered and sorted invoices list
                List {
                    ForEach(filteredInvoices) { invoice in
                        NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                            InvoiceRow(invoice: invoice)
                        }
                    }
                    .onDelete(perform: deleteInvoices)
                }
            }
            .navigationTitle("Invoices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // Title and total owed amount side-by-side
                    HStack {
                        Text("Invoices")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                        Text("Owed: $\(totalAmountOwed, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                }
                
                // Add new invoice button
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateInvoiceView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                if actionSheetType == .category {
                    return ActionSheet(title: Text("Select Job Category"), buttons: jobCategoryPickerButtons())
                } else {
                    return ActionSheet(title: Text("Select Paid Status"), buttons: paidStatusPickerButtons())
                }
            }
        }
    }

    // MARK: - Search, Filter, and Sort Logic
    
    private var filteredInvoices: [Invoice] {
        var filtered = invoices.filter { invoice in
            searchQuery.isEmpty || invoiceMatchesQuery(invoice)
        }
        
        if let selectedJobCategory = selectedJobCategory {
            filtered = filtered.filter { $0.workOrder?.category == selectedJobCategory }
        }
        
        if let selectedPaidStatus = selectedPaidStatus {
            filtered = filtered.filter {
                $0.status?.caseInsensitiveCompare(selectedPaidStatus) == .orderedSame
            }
        }
        
        return filtered.sorted(by: sortOption.comparator)
    }

    private func invoiceMatchesQuery(_ invoice: Invoice) -> Bool {
        let customer = invoice.workOrder?.customer
        let customerName = customer?.name ?? ""
        let customerAddress = customer?.address ?? ""
        let customerPhone = customer?.phoneNumber ?? ""
        
        return customerName.localizedCaseInsensitiveContains(searchQuery)
            || customerAddress.localizedCaseInsensitiveContains(searchQuery)
            || customerPhone.localizedCaseInsensitiveContains(searchQuery)
    }
    
    private func jobCategoryPickerButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = jobCategories.map { category in
            .default(Text(category)) {
                self.selectedJobCategory = category
                self.selectedPaidStatus = nil
            }
        }
        buttons.append(.cancel())
        return buttons
    }
    
    private func paidStatusPickerButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = paidStatuses.map { status in
            .default(Text(status)) {
                self.selectedPaidStatus = status
                self.selectedJobCategory = nil
            }
        }
        buttons.append(.cancel())
        return buttons
    }

    private func toggleDateSort() {
        if case .date(let ascending) = sortOption {
            sortOption = .date(ascending: !ascending)
            self.selectedJobCategory = nil
            self.selectedPaidStatus = nil
        } else {
            sortOption = .date(ascending: true)
        }
    }

    private func deleteInvoices(offsets: IndexSet) {
        for index in offsets {
            let invoiceToDelete = filteredInvoices[index]
            viewContext.delete(invoiceToDelete)
        }

        do {
            try viewContext.save()
        } catch {
            print("Failed to delete invoice: \(error)")
        }
    }
}

// MARK: - InvoiceRow: Displays each invoice in a list row
struct InvoiceRow: View {
    @ObservedObject var invoice: Invoice

    // Compute total amount from both services and materials, including tax
    var totalAmount: Double {
        let serviceTotal = invoice.itemizedServicesArray.reduce(0) { total, service in
            total + (service.unitPrice * Double(service.quantity))
        }
        let materialTotal = invoice.workOrder?.materialsArray.reduce(0) { total, material in
            total + (material.price * Double(material.quantity))
        } ?? 0.0
        let combinedSubtotal = serviceTotal + materialTotal
        let taxAmount = (combinedSubtotal * (invoice.taxPercentage / 100))  // Calculate the tax amount
        return combinedSubtotal + taxAmount
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                // Display customer name and invoice number on the same line
                HStack {
                    Text(invoice.workOrder?.customer?.name ?? "Unknown Customer")
                        .font(.headline)
                    Text("#\(invoice.invoiceNumber)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                if let category = invoice.workOrder?.category {
                    Text("Job Category: \(category)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(invoice.status ?? "Unpaid")
                    .font(.subheadline)
                    .foregroundColor(invoice.status == "Paid" ? .green : .red)
            }
            Spacer()
            Text("$\(totalAmount, specifier: "%.2f")") // Display total amount
                .font(.headline)
        }
    }
}

// MARK: - Sorting Options for Invoices
enum InvoiceSortOption {
    case amount(ascending: Bool)
    case date(ascending: Bool)
    
    var isDateAscending: Bool {
        if case .date(let ascending) = self {
            return ascending
        }
        return true
    }
    
    var comparator: (Invoice, Invoice) -> Bool {
        switch self {
        case .amount(let ascending):
            return { ascending ? $0.computedTotalAmount < $1.computedTotalAmount : $0.computedTotalAmount > $1.computedTotalAmount }
        case .date(let ascending):
            return { ascending ? ($0.issueDate ?? Date()) < ($1.issueDate ?? Date()) : ($0.issueDate ?? Date()) > ($1.issueDate ?? Date()) }
        }
    }
}

// MARK: - Extension to Calculate Total Amount in Invoice
extension Invoice {
    var computedTotalAmount: Double {
        let serviceTotal = itemizedServicesArray.reduce(0) { total, service in
            total + (service.unitPrice * Double(service.quantity))
        }
        let materialTotal = workOrder?.materialsArray.reduce(0) { total, material in
            total + (material.price * Double(material.quantity))
        } ?? 0.0
        let combinedSubtotal = serviceTotal + materialTotal
        let taxAmount = (combinedSubtotal * (self.taxPercentage / 100)) // Calculate the tax
        return combinedSubtotal + taxAmount // Include the tax in the total
    }
}

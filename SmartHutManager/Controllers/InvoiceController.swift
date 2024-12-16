import Foundation
import CoreData
import SwiftUI

class InvoiceController: ObservableObject {
    @Published var invoices: [Invoice] = [] // All fetched invoices
    @Published var uninvoicedWorkOrders: [WorkOrder] = [] // Work orders without invoices
    @Published var searchQuery: String = "" // Search query input
    @Published var selectedJobCategory: String? = nil // Currently selected job category filter
    @Published var selectedPaidStatus: String? = nil // Currently selected paid/unpaid filter
    @Published var sortOption: InvoiceSortOption = .date(ascending: false) // Sort options
    @Published var isShowingUninvoiced: Bool = false // Toggle between invoices and work orders
    
    @Published var jobCategories: [JobCategoryEntity] = [] // Dynamically fetched job categories

    private var viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchJobCategories() // Fetch dynamic categories
        fetchInvoices()
        fetchUninvoicedWorkOrders()
    }

    // MARK: - Fetch Job Categories Dynamically
    func fetchJobCategories() {
        let request: NSFetchRequest<JobCategoryEntity> = JobCategoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JobCategoryEntity.name, ascending: true)]
        
        do {
            self.jobCategories = try viewContext.fetch(request)
        } catch {
            print("Error fetching job categories: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Invoices from CoreData
    func fetchInvoices() {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: false)]
        
        do {
            self.invoices = try viewContext.fetch(request)
        } catch {
            print("Error fetching invoices: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Work Orders Without Invoices
    func fetchUninvoicedWorkOrders() {
        let request: NSFetchRequest<WorkOrder> = WorkOrder.fetchRequest()
        request.predicate = NSPredicate(format: "invoice == nil") // Work orders with no invoices
        
        do {
            self.uninvoicedWorkOrders = try viewContext.fetch(request)
        } catch {
            print("Error fetching uninvoiced work orders: \(error.localizedDescription)")
        }
    }

    // MARK: - Filtered and Sorted Invoices
    var filteredInvoices: [Invoice] {
        var filtered = invoices
        
        // Apply search query filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { invoiceMatchesQuery($0) }
        }
        
        // Apply job category filter
        if let selectedJobCategory = selectedJobCategory {
            filtered = filtered.filter { $0.workOrder?.category == selectedJobCategory }
        }
        
        // Apply paid/unpaid filter
        if let selectedPaidStatus = selectedPaidStatus {
            filtered = filtered.filter { $0.status?.caseInsensitiveCompare(selectedPaidStatus) == .orderedSame }
        }
        
        // Apply sorting
        return filtered.sorted(by: sortOption.comparator)
    }

    // MARK: - Match Search Query
    private func invoiceMatchesQuery(_ invoice: Invoice) -> Bool {
        let customer = invoice.workOrder?.customer
        let customerName = customer?.name ?? ""
        let customerAddress = customer?.address ?? ""
        let customerPhone = customer?.phoneNumber ?? ""
        
        return customerName.localizedCaseInsensitiveContains(searchQuery) ||
               customerAddress.localizedCaseInsensitiveContains(searchQuery) ||
               customerPhone.localizedCaseInsensitiveContains(searchQuery)
    }
    
    // MARK: - Total Amount Owed
    var totalAmountOwed: Double {
        filteredInvoices
            .filter { $0.status == "Unpaid" }
            .reduce(0) { $0 + $1.computedTotalAmount }
    }
    
    // MARK: - Delete Invoices
    func deleteInvoices(at indexSet: IndexSet) {
        for index in indexSet {
            let invoiceToDelete = filteredInvoices[index]
            viewContext.delete(invoiceToDelete)
        }
        
        saveContext()
        fetchInvoices()
    }
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save after deleting invoices: \(error.localizedDescription)")
        }
    }

    // MARK: - Toggle Filters
    func togglePaidStatus(_ status: String) {
        selectedPaidStatus = (selectedPaidStatus == status) ? nil : status
        fetchInvoices()
    }

    func toggleJobCategory(_ category: String) {
        selectedJobCategory = (selectedJobCategory == category) ? nil : category
        fetchInvoices()
    }
    
    // MARK: - Toggle Between Invoices and Work Orders
    func toggleUninvoicedView() {
        isShowingUninvoiced.toggle()
    }

    // MARK: - Sort Options
    func toggleDateSort() {
        if case .date(let ascending) = sortOption {
            sortOption = .date(ascending: !ascending)
        } else {
            sortOption = .date(ascending: true)
        }
    }
}

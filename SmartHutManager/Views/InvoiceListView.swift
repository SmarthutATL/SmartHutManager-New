import SwiftUI
import CoreData

struct InvoiceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var controller: InvoiceController
    
    init(viewContext: NSManagedObjectContext) {
        _controller = StateObject(wrappedValue: InvoiceController(viewContext: viewContext))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Filters and Sorting Header
                    headerView
                    
                    // Toggle View Button
                    toggleViewButton
                    
                    // Filters Section
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "Paid", isSelected: controller.selectedPaidStatus == "Paid") {
                                controller.togglePaidStatus("Paid")
                            }
                            FilterChip(title: "Unpaid", isSelected: controller.selectedPaidStatus == "Unpaid") {
                                controller.togglePaidStatus("Unpaid")
                            }
                            ForEach(controller.jobCategories, id: \.self) { categoryEntity in
                                FilterChip(
                                    title: categoryEntity.name ?? "Unknown Category",
                                    isSelected: controller.selectedJobCategory == categoryEntity.name
                                ) {
                                    controller.toggleJobCategory(categoryEntity.name ?? "")
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 5)
                    
                    // Invoice or Uninvoiced Work Order List
                    if controller.isShowingUninvoiced {
                        // Display Work Orders Without Invoices
                        if controller.uninvoicedWorkOrders.isEmpty {
                            emptyStateView(message: "All work orders have invoices.")
                        } else {
                            List {
                                ForEach(controller.uninvoicedWorkOrders, id: \.self) { workOrder in
                                    NavigationLink {
                                        WorkOrderDetailView(workOrder: workOrder)
                                    } label: {
                                        UninvoicedWorkOrderRow(workOrder: workOrder)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    } else {
                        // Display Filtered Invoices
                        if controller.filteredInvoices.isEmpty {
                            emptyStateView(message: "No Invoices Found")
                        } else {
                            List {
                                ForEach(controller.filteredInvoices) { invoice in
                                    NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                        InvoiceRow(invoice: invoice)
                                    }
                                }
                                .onDelete { indexSet in
                                    controller.deleteInvoices(at: indexSet)
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
                .navigationTitle(controller.isShowingUninvoiced ? "Uninvoiced Work Orders" : "Invoices")
                .searchable(text: $controller.searchQuery, prompt: controller.isShowingUninvoiced ? "Search work orders..." : "Search invoices...")
                
                // Floating Add Invoice Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            controller.showCreateInvoiceView.toggle()
                        }) {
                            Image(systemName: "note.text.badge.plus")
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
            // Sheet to display CreateInvoiceView
            .sheet(isPresented: $controller.showCreateInvoiceView) {
                CreateInvoiceView()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            if !controller.isShowingUninvoiced {
                Button(action: {
                    withAnimation(.easeInOut) {
                        controller.toggleTotalOwedVisibility()
                    }
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Owed")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if controller.isTotalOwedVisible {
                                Text("$\(controller.totalAmountOwed, specifier: "%.2f")")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                            } else {
                                Text("Tap to View")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            Menu {
                Section(header: Text("Sort Options")) {
                    Button("Date (\(controller.sortOption.isDateAscending ? "Newest" : "Oldest") First)") {
                        controller.toggleDateSort()
                    }
                    Button("Amount (Low to High)") {
                        controller.sortOption = .amount(ascending: true)
                    }
                    Button("Amount (High to Low)") {
                        controller.sortOption = .amount(ascending: false)
                    }
                }
            } label: {
                Image(systemName: "line.horizontal.3.decrease.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
    // MARK: - Toggle View Button
    private var toggleViewButton: some View {
        Button(action: controller.toggleUninvoicedView) {
            Text(controller.isShowingUninvoiced ? "Show Invoices" : "Show Work Orders Without Invoices")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .padding(.horizontal)
        }
    }
    
    // MARK: - Empty State View
    private func emptyStateView(message: String) -> some View {
        VStack {
            Spacer()
            Text(message)
                .font(.title2)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

// MARK: - FilterChip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .blue : .primary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Uninvoiced Work Order Row
struct UninvoicedWorkOrderRow: View {
    let workOrder: WorkOrder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(workOrder.customer?.name ?? "Unknown Customer")
                .font(.headline)
            Text("Category: \(workOrder.category ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Date: \(workOrder.date ?? Date(), style: .date)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

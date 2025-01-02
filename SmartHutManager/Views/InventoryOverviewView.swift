import SwiftUI
import CoreData

struct InventoryOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: InventoryViewModel
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .name(ascending: true)
    @State private var selectedFilter: String? = nil
    @State private var selectedTradesman: Tradesmen? = nil
    @State private var itemToAssign: Inventory? = nil
    @State private var itemToEdit: Inventory? = nil
    @State private var isAddingNewItem = false
    @State private var isEditingThresholds = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: InventoryViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) { // Compact vertical spacing
                // Combined Header: Sort Menu + Tradesmen Dropdown
                headerView

                // Filter Chips
                filterChips

                // Inventory List
                inventoryList
            }
            .navigationTitle("Inventory Overview")
            .searchable(text: $searchQuery)
            .padding(.horizontal, 16) // Uniform padding
            .sheet(isPresented: $isAddingNewItem) {
                AddNewItemView(
                    isAddingNewItem: $isAddingNewItem,
                    onSave: { name, price, quantity in
                        viewModel.saveNewItem(name: name, price: price, quantity: quantity)
                    }
                )
            }
            .sheet(item: $itemToAssign) { item in
                AssignInventoryView(
                    item: item,
                    tradesmen: viewModel.tradesmen,
                    onAssign: { tradesman, quantity in
                        viewModel.assignItemToTradesman(item: item, tradesman: tradesman, quantity: quantity)
                    }
                )
            }
            .sheet(item: $itemToEdit) { item in
                EditInventoryItemView(item: item)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(isPresented: $isEditingThresholds) {
                EditThresholdsView()
                    .environment(\.managedObjectContext, viewContext)
            }

            floatingAddButton
        }
    }

    // MARK: - Combined Header View
    private var headerView: some View {
        HStack {
            // Redesigned Tradesmen Dropdown
            Menu {
                Picker(selection: $selectedTradesman, label: Text("Filter by Tradesman")) {
                    Text("All Inventory").tag(nil as Tradesmen?)
                    ForEach(viewModel.tradesmen, id: \.self) { tradesman in
                        Text(tradesman.name ?? "Unknown").tag(tradesman as Tradesmen?)
                    }
                }
            } label: {
                HStack {
                    Text(selectedTradesman == nil ? "All Inventory" : selectedTradesman?.name ?? "Technician")
                        .foregroundColor(.primary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
            }

            Spacer()

            // Sort Menu
            sortMenu
        }
        .padding(.vertical, 8) // Add slight padding for a clean look
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Low Stock", isSelected: selectedFilter == "Low Stock") {
                    selectedFilter = selectedFilter == "Low Stock" ? nil : "Low Stock"
                }
                FilterChip(title: "High Stock", isSelected: selectedFilter == "High Stock") {
                    selectedFilter = selectedFilter == "High Stock" ? nil : "High Stock"
                }
                FilterChip(title: "All Items", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
            }
            .padding(.vertical, 5)
        }
    }

    // MARK: - Inventory List
    private var inventoryList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(filteredAndSortedItems, id: \.self) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Price: $\(item.price, specifier: "%.2f") | Qty: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            if let tradesman = item.tradesmen {
                                Text("Assigned to \(tradesman.name ?? "Technician")")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("In Warehouse")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }

                        Spacer()

                        if item.tradesmen == nil {
                            Button(action: {
                                itemToAssign = item
                            }) {
                                Text("Assign")
                                    .font(.caption)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .contextMenu {
                        Button("Edit") {
                            itemToEdit = item
                        }
                        Button("Delete", role: .destructive) {
                            viewModel.deleteItem(item)
                        }
                    }
                }
            }
            .padding(.vertical, 8) // Padding to separate from edges
        }
    }

    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { isAddingNewItem = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
    }

    // MARK: - Sort Menu
    private var sortMenu: some View {
        Menu {
            Section(header: Text("Sort Options")) {
                Button("Name (\(sortOption == .name(ascending: true) ? "A-Z" : "Z-A"))") {
                    sortOption = sortOption == .name(ascending: true) ? .name(ascending: false) : .name(ascending: true)
                }
                Button("Price (Low to High)") { sortOption = .price(ascending: true) }
                Button("Price (High to Low)") { sortOption = .price(ascending: false) }
            }
            Button("Edit Thresholds") {
                isEditingThresholds = true
            }
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }

    // MARK: - Filtering and Sorting Logic
    private var filteredAndSortedItems: [Inventory] {
        var items = viewModel.inventoryItems

        // Apply search filter
        if !searchQuery.isEmpty {
            items = items.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchQuery) }
        }

        // Apply tradesmen filter
        if let tradesman = selectedTradesman {
            items = items.filter { $0.tradesmen == tradesman }
        }

        // Apply stock filters
        if selectedFilter == "Low Stock" {
            items = items.filter { $0.quantity < $0.lowStockThreshold }
        } else if selectedFilter == "High Stock" {
            items = items.filter { $0.quantity >= $0.highStockThreshold }
        }

        // Sort items
        return items.sorted { sortOption.comparator($0, $1) }
    }
}

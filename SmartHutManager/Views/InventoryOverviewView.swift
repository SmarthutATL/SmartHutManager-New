import SwiftUI
import CoreData

struct InventoryOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: InventoryViewModel
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .name(ascending: true)
    @State private var selectedFilters: Set<String> = [] // Allow multiple filters
    @State private var selectedCategory: String? = nil
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
            ZStack {
                VStack(spacing: 12) {
                    // Combined Header: Sort Menu + Tradesmen Dropdown
                    headerView
                    
                    // Category Filter Chips
                    categoryFilterChips
                    
                    // Filter Chips (e.g., Low Stock, In Warehouse, Assigned to Tradesmen)
                    filterChips
                    
                    // Inventory List
                    inventoryList
                }
                .navigationTitle("Inventory Overview")
                .searchable(text: $searchQuery)
                .padding(.horizontal, 16)
                .sheet(isPresented: $isAddingNewItem) {
                    AddNewItemView(
                        isAddingNewItem: $isAddingNewItem,
                        onSave: { name, price, quantity, category in
                            viewModel.saveNewItem(name: name, price: price, quantity: quantity, category: category)
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

                // Floating Add Button
                floatingAddButton
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 16) {
            // Tradesmen Dropdown
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
        .padding(.vertical, 8)
    }
    
    // MARK: - Category Filter Chips
    private var categoryFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All Categories", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(viewModel.categories, id: \.self) { category in
                    FilterChip(title: category, isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "Low Stock", isSelected: selectedFilters.contains("Low Stock")) {
                    toggleFilter("Low Stock")
                }
                FilterChip(title: "High Stock", isSelected: selectedFilters.contains("High Stock")) {
                    toggleFilter("High Stock")
                }
                FilterChip(title: "In Warehouse", isSelected: selectedFilters.contains("In Warehouse")) {
                    setExclusiveFilter("In Warehouse")
                }
                FilterChip(title: "Assigned to Tradesmen", isSelected: selectedFilters.contains("Assigned to Tradesmen")) {
                    setExclusiveFilter("Assigned to Tradesmen")
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
                            Text("Category: \(item.inventoryCategory ?? "None")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Price: $\(item.price, specifier: "%.2f") | Qty: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if let tradesman = item.tradesmen {
                                Text("Assigned to \(tradesman.name ?? "Technician")")
                                    .font(.caption)
                                    .foregroundColor(.blue)
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
            .padding(.vertical, 8)
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
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
    
    // MARK: - Filtering and Sorting Logic
    private var filteredAndSortedItems: [Inventory] {
        var items = viewModel.inventoryItems

        // Filter by selected tradesman
        if let tradesman = selectedTradesman {
            items = items.filter { $0.tradesmen == tradesman }
        }

        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.inventoryCategory == category }
        }

        // Apply filter chips
        if selectedFilters.contains("In Warehouse") {
            items = items.filter { $0.tradesmen == nil }
        } else if selectedFilters.contains("Assigned to Tradesmen") {
            items = items.filter { $0.tradesmen != nil }
        }
        if selectedFilters.contains("Low Stock") {
            items = items.filter { $0.quantity <= $0.lowStockThreshold }
        }
        if selectedFilters.contains("High Stock") {
            items = items.filter { $0.quantity > $0.highStockThreshold }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            items = items.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchQuery) }
        }

        // Sort items
        return items.sorted { sortOption.comparator($0, $1) }
    }
    
    // MARK: - Toggle and Exclusive Filters
    private func toggleFilter(_ filter: String) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
    }

    private func setExclusiveFilter(_ filter: String) {
        // Remove mutually exclusive filters
        selectedFilters.remove("In Warehouse")
        selectedFilters.remove("Assigned to Tradesmen")
        if !selectedFilters.contains(filter) {
            selectedFilters.insert(filter)
        }
    }
}

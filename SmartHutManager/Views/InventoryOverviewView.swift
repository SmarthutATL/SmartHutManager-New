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
            ZStack {
                VStack {
                    headerView
                    tradesmenDropdown
                    filterChips
                    inventoryList
                }
                .navigationTitle("Inventory Overview")
                .searchable(text: $searchQuery)

                floatingAddButton
            }
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
        }
    }

    private var headerView: some View {
        HStack {
            Spacer() // Add space to push the sort menu to the right
            sortMenu
        }
        .padding(.horizontal)
    }

    private var tradesmenDropdown: some View {
        Picker("Filter by Tradesman", selection: $selectedTradesman) {
            Text("All Inventory").tag(nil as Tradesmen?)
            ForEach(viewModel.tradesmen, id: \.self) { tradesman in
                Text(tradesman.name ?? "Unknown").tag(tradesman as Tradesmen?)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(.horizontal)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
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
            .padding(.horizontal)
        }
    }

    private var inventoryList: some View {
        List(filteredAndSortedItems, id: \.self) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name ?? "Unknown").font(.headline)
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

                // Assign button
                if item.tradesmen == nil {
                    Button(action: {
                        itemToAssign = item
                    }) {
                        Text("Assign to Tradesman")
                            .font(.caption)
                            .padding(6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            // Long-press to show context menu
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

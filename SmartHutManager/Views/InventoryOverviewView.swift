import SwiftUI
import CoreData

struct InventoryOverviewView: View {
    @Environment(\.managedObjectContext) private var viewContext // Access Core Data context
    @StateObject private var viewModel: InventoryViewModel
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .name(ascending: true)
    @State private var selectedFilter: String? = nil
    @State private var isAddingNewItem = false

    // Initialize the view model with the Core Data context
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: InventoryViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    headerView
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
        }
    }

    private var headerView: some View {
        HStack {
            if selectedFilter == nil {
                Text("Total Items: \(viewModel.inventoryItems.count)")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            Spacer()
            sortMenu
        }
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
            }
            .contextMenu {
                Button("Edit") {
                    // Add edit functionality here
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
        } label: {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }

    private var filteredAndSortedItems: [Inventory] {
        var items = viewModel.inventoryItems
        if !searchQuery.isEmpty {
            items = items.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchQuery) }
        }
        if selectedFilter == "Low Stock" {
            items = items.filter { $0.quantity < 10 }
        } else if selectedFilter == "High Stock" {
            items = items.filter { $0.quantity >= 10 }
        }
        return items.sorted { sortOption.comparator($0, $1) }
    }
}

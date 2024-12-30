import SwiftUI

struct InventoryOverviewView: View {
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .name(ascending: true)
    @State private var selectedFilter: String? = nil // Tracks the selected filter
    @State private var inventoryItems: [Material] = []
    @State private var isAddingNewItem = false
    @State private var newItem = Material(name: "", price: 0.0, quantity: 0)

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // Header with filters and sort options
                    headerView
                    
                    // Filters Section
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterChip(title: "Low Stock", isSelected: selectedFilter == "Low Stock") {
                                selectedFilter = selectedFilter == "Low Stock" ? nil : "Low Stock"
                                applyFilter()
                            }
                            FilterChip(title: "High Stock", isSelected: selectedFilter == "High Stock") {
                                selectedFilter = selectedFilter == "High Stock" ? nil : "High Stock"
                                applyFilter()
                            }
                            FilterChip(title: "All Items", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                                applyFilter()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 5)

                    // Inventory List
                    inventoryList
                }
                .navigationTitle("Inventory Overview")
                .searchable(text: $searchQuery, prompt: "Search inventory...")

                // Floating Add Item Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            isAddingNewItem = true
                            print("Add New Item Floating Button Tapped")
                        }) {
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
            .sheet(isPresented: $isAddingNewItem) {
                AddNewItemView(
                    newItem: $newItem,
                    isAddingNewItem: $isAddingNewItem,
                    onSave: saveNewItem
                )
            }
            .onAppear {
                loadInventoryItems()
                print("Inventory Overview View Loaded")
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            if selectedFilter == nil { // Show total count when no filter applied
                Text("Total Items: \(inventoryItems.count)")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            
            Spacer()

            Menu {
                Section(header: Text("Sort Options")) {
                    Button("Name (\(sortOption == .name(ascending: true) ? "A-Z" : "Z-A"))") {
                        sortOption = (sortOption == .name(ascending: true)) ? .name(ascending: false) : .name(ascending: true)
                        applySort()
                    }
                    Button("Price (Low to High)") {
                        sortOption = .price(ascending: true)
                        applySort()
                    }
                    Button("Price (High to Low)") {
                        sortOption = .price(ascending: false)
                        applySort()
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

    // MARK: - Inventory List
    private var inventoryList: some View {
        List(filteredAndSortedItems) { item in
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                Text("Price: $\(item.price, specifier: "%.2f") | Qty: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Filtered and Sorted Items
    private var filteredAndSortedItems: [Material] {
        var filtered = inventoryItems

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        // Apply stock filter
        if let selectedFilter = selectedFilter {
            if selectedFilter == "Low Stock" {
                filtered = filtered.filter { $0.quantity < 10 }
            } else if selectedFilter == "High Stock" {
                filtered = filtered.filter { $0.quantity >= 10 }
            }
        }

        // Apply sorting
        return filtered.sorted { sortOption.comparator($0, $1) }
    }

    // MARK: - Apply Filters and Sorting
    private func applyFilter() {
        print("Filter applied: \(selectedFilter ?? "All Items")")
    }

    private func applySort() {
        print("Sort applied: \(sortOption.displayName)")
    }

    // MARK: - Load Inventory Items
    private func loadInventoryItems() {
        inventoryItems = [
            Material(name: "TV Mount", price: 45.99, quantity: 10),
            Material(name: "Wall Anchors", price: 12.99, quantity: 50),
            Material(name: "Outlet Box", price: 5.49, quantity: 30)
        ]
        print("Inventory Items Loaded: \(inventoryItems)")
    }

    // MARK: - Save New Item
    private func saveNewItem() {
        guard !newItem.name.isEmpty, newItem.price > 0, newItem.quantity > 0 else {
            print("Invalid New Item")
            return
        }
        inventoryItems.append(newItem)
        print("Saved New Item: \(newItem)")
        newItem = Material(name: "", price: 0.0, quantity: 0)
    }
}

import SwiftUI
import CoreData

struct ManageInventoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: InventoryViewModel
    @State private var searchQuery: String = ""
    @State private var selectedTradesman: Tradesmen? = nil
    @State private var isAddingNewItem = false
    @State private var selectedItem: Inventory? = nil

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: InventoryViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            VStack {
                headerView
                tradesmenDropdown
                inventoryList
            }
            .navigationTitle("Manage Inventory")
            .searchable(text: $searchQuery)
            .sheet(item: $selectedItem) { item in
                AssignInventoryView(
                    item: item,
                    tradesmen: viewModel.tradesmen,
                    onAssign: { tradesman, quantity in
                        viewModel.assignItemToTradesman(item: item, tradesman: tradesman, quantity: quantity)
                    }
                )
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
            Text("Warehouse Inventory: \(viewModel.warehouseInventoryCount)")
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
            Button(action: { isAddingNewItem = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
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

    private var inventoryList: some View {
        List(filteredAndSortedItems, id: \.self) { item in
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name ?? "Unknown").font(.headline)
                Text("Price: $\(item.price, specifier: "%.2f") | Qty: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                if let tradesman = item.tradesmen {
                    Text("In \(tradesman.name ?? "Technician")'s Inventory")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("In Warehouse")
                        .font(.caption)
                        .foregroundColor(.green)
                }

                // Show "Assign to Tradesman" button only if in "All Inventory" and item is not assigned
                if selectedTradesman == nil && item.tradesmen == nil {
                    Button(action: { selectedItem = item }) {
                        Text("Assign to Tradesman")
                            .font(.caption)
                            .padding(6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        }
        .listStyle(PlainListStyle())
        .listRowInsets(EdgeInsets())
    }

    private var filteredAndSortedItems: [Inventory] {
        var items = viewModel.inventoryItems

        // Apply search filter
        if !searchQuery.isEmpty {
            items = items.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchQuery) }
        }

        // Filter by selected tradesman
        if let tradesman = selectedTradesman {
            items = items.filter { $0.tradesmen == tradesman }
        }

        return items
    }
}

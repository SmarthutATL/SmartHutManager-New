import SwiftUI
import CoreData
import MessageUI // Import MessageUI for sending texts

struct WorkOrderListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch work orders with minimal data to optimize load times
    @FetchRequest(
        entity: WorkOrder.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkOrder.date, ascending: true)],
        predicate: NSPredicate(format: "date != nil"), // Only fetch work orders with a date
        animation: .default
    )
    private var workOrders: FetchedResults<WorkOrder>
    
    // Fetch all tradesmen/technicians for filtering
    @FetchRequest(
        entity: Tradesmen.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Tradesmen.name, ascending: true)]
    ) private var tradesmen: FetchedResults<Tradesmen>
    
    @State private var searchQuery: String = ""
    @State private var sortOption: SortOption = .date(ascending: true) // Start with ascending date sort
    @State private var selectedCategory: String? = nil // Track selected category for filtering
    @State private var selectedStatus: String? = nil // Track selected status for filtering
    @State private var selectedTechnician: Tradesmen? = nil // Track selected technician for filtering
    @State private var showingMessageCompose = false
    @State private var selectedWorkOrder: WorkOrder? // Track the selected work order for text
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEditing = false // Track if we're in edit mode
    @State private var showingActionSheet = false // Single action sheet state
    @State private var actionSheetType: ActionSheetType = .none // Track action sheet type
    
    // Enum to track which action sheet to show
    enum ActionSheetType {
        case category
        case status
        case technician // Add technician action sheet
        case none
    }
    
    // List of categories
    let categories = [
        "Accent Wall", "Camera Installation", "Drywall Repair", "Electrical", "Furniture Assembly",
        "General Handyman", "Home Theater Installation", "Lighting", "Painting", "Picture Hanging",
        "Plumbing", "Pressure Washing", "TV Mounting"
    ]
    
    // List of statuses
    let statuses = ["Open", "Completed", "Incomplete"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar and Filter/Sort Buttons
                HStack {
                    TextField("Search work orders...", text: $searchQuery)
                        .padding(.leading, 8)
                        .frame(height: 36)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    // Sort Menu
                    Menu {
                        Button(action: {
                            toggleDateSort()
                        }) { Text("Sort by Date (\(sortOption.isDateAscending ? "Newest" : "Oldest") First)") }
                        Button(action: {
                            sortOption = .workOrderNumber // Add more sorting options
                        }) { Text("Sort by Work Order Number") }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                            .font(.title2)
                    }
                    .padding(.trailing, 8)
                    
                    // Filter Menu
                    Menu {
                        Button(action: {
                            actionSheetType = .status
                            showingActionSheet = true
                        }) {
                            Text("Filter by Status")
                        }

                        Button(action: {
                            actionSheetType = .category
                            showingActionSheet = true
                        }) {
                            Text("Filter by Category")
                        }
                        
                        Button(action: {
                            actionSheetType = .technician // Action sheet for technician filter
                            showingActionSheet = true
                        }) {
                            Text("Filter by Technician")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.horizontal.3.decrease.circle")
                            .font(.title2)
                    }
                    .padding(.trailing, 8)
                }
                .padding([.horizontal, .top])
                
                // Status Filter Info
                if let selectedStatus = selectedStatus {
                    HStack {
                        Text("Filtering by Status: \(selectedStatus)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button(action: {
                            self.selectedStatus = nil // Clear status filter
                        }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Category Filter Info
                if let selectedCategory = selectedCategory {
                    HStack {
                        Text("Filtering by Category: \(selectedCategory)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button(action: {
                            self.selectedCategory = nil // Clear category filter
                        }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Technician Filter Info
                if let selectedTechnician = selectedTechnician {
                    HStack {
                        Text("Filtering by Technician: \(selectedTechnician.name ?? "No Name")")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Spacer()
                        Button(action: {
                            self.selectedTechnician = nil // Clear technician filter
                        }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }

                // Filtered Work Orders List
                List {
                    ForEach(filteredWorkOrders) { workOrder in
                        HStack {
                            NavigationLink(destination: WorkOrderDetailView(workOrder: workOrder)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    // Display work order number with callback if applicable
                                    HStack {
                                        Text("Work Order #\(workOrder.workOrderNumber)")
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        if workOrder.isCallback {
                                            Text("callback")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    
                                    Text(workOrder.category ?? "No Category")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Customer: \(workOrder.customer?.name ?? "No Customer")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    // Display the scheduled date and time
                                    if let workOrderDate = workOrder.date {
                                        HStack {
                                            Text("Scheduled: \(formattedDate(workOrderDate))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            if let workOrderTime = workOrder.time {
                                                Text("at \(formattedTime(workOrderTime))")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }

                                    // Display assigned tradesmen
                                    if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen>, !tradesmenSet.isEmpty {
                                        Text("Technicians: \(tradesmenSet.compactMap { $0.name }.joined(separator: ", "))")
                                            .font(.subheadline)
                                            .foregroundColor(.blue) // Yellow for technicians assigned
                                    } else {
                                        Text("No technicians assigned")
                                            .font(.subheadline)
                                            .foregroundColor(.red) // Red if no technicians are assigned
                                    }

                                    // Display the status of the work order with color
                                    Text("Status: \(workOrder.status ?? "No Status")")
                                        .font(.caption)
                                        .foregroundColor(statusColor(for: workOrder.status))
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if !isEditing {
                                // Message Button
                                Button {
                                    selectedWorkOrder = workOrder
                                    if let customerPhone = workOrder.customer?.phoneNumber, !customerPhone.isEmpty {
                                        DispatchQueue.main.async {
                                            showingMessageCompose = true
                                        }
                                    } else {
                                        alertMessage = "Unable to send message. No customer phone number available."
                                        showAlert = true
                                    }
                                } label: {
                                    Label("Message", systemImage: "message")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkOrders) // Enable swipe-to-delete in edit mode
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Work Orders")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .onChange(of: isEditing) { oldValue, newValue in
                            isEditing = newValue
                        }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingMessageCompose, onDismiss: {
                selectedWorkOrder = nil // Clear selected work order after dismissing
            }) {
                if let selectedWorkOrder = selectedWorkOrder,
                   let customerPhone = selectedWorkOrder.customer?.phoneNumber {
                    MessageComposeView(recipients: [customerPhone], body: buildConfirmationText(for: selectedWorkOrder))
                }
            }
            .actionSheet(isPresented: $showingActionSheet) {
                if actionSheetType == .category {
                    return ActionSheet(title: Text("Select a Category"), buttons: categoryPickerButtons())
                } else if actionSheetType == .status {
                    return ActionSheet(title: Text("Select a Status"), buttons: statusPickerButtons())
                } else if actionSheetType == .technician {
                    return ActionSheet(title: Text("Select a Technician"), buttons: technicianPickerButtons())
                } else {
                    return ActionSheet(title: Text(""), buttons: [.cancel()])
                }
            }
        }
    }

    // Generate category buttons for ActionSheet
    private func categoryPickerButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = categories.map { category in
            .default(Text(category)) {
                self.selectedCategory = category
                self.selectedStatus = nil // Clear status when selecting category
            }
        }
        buttons.append(.cancel())
        return buttons
    }
    
    // Generate status buttons for ActionSheet
    private func statusPickerButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = statuses.map { status in
            .default(Text(status)) {
                self.selectedStatus = status
                self.selectedCategory = nil // Clear category when selecting status
            }
        }
        buttons.append(.cancel())
        return buttons
    }

    // Generate technician buttons for ActionSheet
    private func technicianPickerButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = tradesmen.map { technician in
            .default(Text(technician.name ?? "No Name")) {
                self.selectedTechnician = technician
            }
        }
        buttons.append(.cancel())
        return buttons
    }

    // Toggle the date sorting between ascending and descending
    private func toggleDateSort() {
        if case .date(let ascending) = sortOption {
            sortOption = .date(ascending: !ascending) // Toggle the sort direction
            self.selectedCategory = nil
            self.selectedStatus = nil // Clear all filters when sorting by date
        } else {
            sortOption = .date(ascending: true) // Default to ascending if not already sorting by date
        }
    }

    // Filter work orders by search query, selected category, selected status, selected technician, and apply sorting
    private var filteredWorkOrders: [WorkOrder] {
        var filtered = workOrders.filter { workOrder in
            searchQuery.isEmpty || workOrderMatchesQuery(workOrder)
        }
        
        // Apply category filter if selected
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply status filter if selected
        if let selectedStatus = selectedStatus {
            filtered = filtered.filter { $0.status == selectedStatus }
        }
        
        // Apply technician filter if selected
        if let selectedTechnician = selectedTechnician {
            filtered = filtered.filter { workOrder in
                if let tradesmenSet = workOrder.tradesmen as? Set<Tradesmen> {
                    return tradesmenSet.contains { $0 == selectedTechnician }
                }
                return false
            }
        }
        
        return filtered.sorted(by: sortOption.comparator)
    }

    // Check if a work order matches the search query
    private func workOrderMatchesQuery(_ workOrder: WorkOrder) -> Bool {
        if let customerName = workOrder.customer?.name, customerName.localizedCaseInsensitiveContains(searchQuery) {
            return true
        }
        if let category = workOrder.category, category.localizedCaseInsensitiveContains(searchQuery) {
            return true
        }
        return false
    }

    // Function to handle deletion of work orders
    private func deleteWorkOrders(at offsets: IndexSet) {
        for index in offsets {
            let workOrderToDelete = filteredWorkOrders[index]
            deleteWorkOrder(workOrderToDelete)
        }
    }

    private func deleteWorkOrder(_ workOrder: WorkOrder) {
        viewContext.delete(workOrder)
        
        do {
            try viewContext.save() // Save changes to Core Data after deletion
        } catch {
            print("Failed to delete work order: \(error.localizedDescription)")
        }
    }

    // Helper function to format dates
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }

    // Helper function to format times
    private func formattedTime(_ time: Date) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: time)
    }

    // Build confirmation text for customer
    private func buildConfirmationText(for workOrder: WorkOrder) -> String {
        var message = "Hello, your work order (#\(workOrder.workOrderNumber)) for \(workOrder.category ?? "N/A")"
        if let date = workOrder.date, let time = workOrder.time {
            message += " is scheduled for \(formattedDate(date)) at \(formattedTime(time))."
        }
        message += " Please confirm by replying to this message. Thank you!"
        return message
    }

    // Helper function to determine the color of the status text
    private func statusColor(for status: String?) -> Color {
        switch status?.lowercased() {
        case "open":
            return .red
        case "completed":
            return .green
        case "incomplete":
            return .yellow
        default:
            return .gray
        }
    }
}


// MessageComposeView for sending text messages
struct MessageComposeView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView
        
        init(_ parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            controller.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}
}

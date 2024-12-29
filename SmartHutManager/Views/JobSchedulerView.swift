import SwiftUI
import CoreData
import FSCalendar

// Wrapper struct to hold WorkOrder and hide logic
struct DisplayableWorkOrder: Identifiable {
    let workOrder: WorkOrder
    let isHidden: Bool

    // Conform to Identifiable using the work order's id
    var id: NSManagedObjectID {
        return workOrder.objectID
    }
}

// Main Job Scheduler View with Day, Week, and Month views using FSCalendar
struct JobSchedulerView: View {
    @EnvironmentObject var deletedItemsManager: DeletedItemsManager
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel  // Access user role information
    
    @AppStorage("isDarkMode") private var isDarkMode: Bool = true // Read dark mode setting
    
    let userName: String // Pass the user's name to dynamically set the title
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WorkOrder.date, ascending: true)],
        animation: .default
    ) private var workOrders: FetchedResults<WorkOrder>
    
    @State private var selectedDate = Date()  // Track selected date on the calendar
    @State private var isPresentingNewWorkOrder = false  // Modal for creating a new work order
    @State private var isPresentingWorkOrderList = false  // Modal for viewing all work orders
    @State private var calendarScope: FSCalendarScope = .month  // Start with month view
    @State private var workOrderToReschedule: WorkOrder? = nil  // Track work order to reschedule
    @State private var isShowingReschedulePicker = false  // Modal for rescheduling work order
    @State private var workOrderToDelete: WorkOrder? = nil
    @State private var isShowingDeleteConfirmation = false
    @State private var isShowingDeleteSlider = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Toolbar (only visible for admins)
                if authViewModel.userRole == "admin" {
                    HStack {
                        Button(action: {
                            isPresentingWorkOrderList.toggle()
                        }) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                        .sheet(isPresented: $isPresentingWorkOrderList) {
                            WorkOrderListView()
                                .environment(\.managedObjectContext, viewContext)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isPresentingNewWorkOrder.toggle()
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                        .sheet(isPresented: $isPresentingNewWorkOrder) {
                            NewWorkOrderView(selectedDate: selectedDate)
                                .environment(\.managedObjectContext, viewContext)
                        }
                    }
                    .padding([.horizontal, .top])
                }
                
                // Segmented Picker for Day, Week, and Month Views
                Picker("View Type", selection: $calendarScope) {
                    Text("Week").tag(FSCalendarScope.week)
                    Text("Month").tag(FSCalendarScope.month)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // FSCalendar View
                CalendarView(
                    selectedDate: $selectedDate,
                    calendarScope: $calendarScope,
                    workOrders: displayedWorkOrders.map { $0.workOrder },
                    isPresentingNewWorkOrder: $isPresentingNewWorkOrder,
                    isDarkMode: $isDarkMode // Pass the dark mode state
                )
                .background(isDarkMode ? Color.black : Color.white) // Dynamic calendar background
                .frame(height: calendarScope == .month ? 400 : 300)
                .padding(.top, 20)
                
                // List of work orders for the selected date
                if workOrdersForSelectedDate.isEmpty {
                    Text("No work orders for \(formattedDate(selectedDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                } else {
                    List {
                        ForEach(workOrdersForSelectedDate) { displayableOrder in
                            HStack {
                                NavigationLink(destination: WorkOrderDetailView(workOrder: displayableOrder.workOrder)) {
                                    VStack(alignment: .leading) {
                                        HStack(spacing: 5) {
                                            Text(displayableOrder.workOrder.customer?.name ?? "Unknown")
                                                .font(.headline)
                                                .foregroundColor(isDarkMode ? .white : .black) // Dynamic text color
                                            
                                            Text("#\(displayableOrder.workOrder.workOrderNumber)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(isDarkMode ? .white : .black)
                                        }
                                        Text(displayableOrder.workOrder.category ?? "No Category")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        Text("Status: \(displayableOrder.workOrder.status ?? "No Status")")
                                            .font(.caption)
                                            .foregroundColor(statusColor(for: displayableOrder.workOrder.status))
                                        if let workOrderTime = displayableOrder.workOrder.time {
                                            Text("Arrival Time: \(formattedTime(workOrderTime))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        if let tradesmenSet = displayableOrder.workOrder.tradesmen as? Set<Tradesmen>, !tradesmenSet.isEmpty {
                                            let tradesmenNames = tradesmenSet.compactMap { $0.name }.joined(separator: ", ")
                                            Text("Technician(s): \(tradesmenNames)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                if authViewModel.userRole == "admin" {
                                    Button(action: {
                                        workOrderToReschedule = displayableOrder.workOrder
                                        isShowingReschedulePicker = true
                                    }) {
                                        Text("Reschedule")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 5)
                                            .padding(.horizontal, 12)
                                            .background(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.orange, Color.orange]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .cornerRadius(8)
                                            .shadow(radius: 5)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.leading, 10)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) { // Prevent full swipe
                                if authViewModel.userRole == "admin" {
                                    // Message Button
                                    Button {
                                        sendConfirmationMessage(to: displayableOrder.workOrder)
                                    } label: {
                                        Label("Message", systemImage: "message.fill")
                                    }
                                    .tint(.green) // Message button color
                                    
                                    // Delete Button
                                    Button(role: .destructive) {
                                        confirmDelete(workOrder: displayableOrder.workOrder)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .tint(.red) // Delete button color
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Add the delete slider
                if isShowingDeleteSlider {
                    VStack {
                        Text("Slide to confirm deletion")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        ConfirmationSlider(action: finalizeDelete)
                            .padding()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                }
            }
            .navigationTitle("\(userName)'s Schedule") // Dynamically display the user's name
            .background(isDarkMode ? Color.black.edgesIgnoringSafeArea(.all) : Color.white.edgesIgnoringSafeArea(.all)) // Dynamic view background
            .sheet(isPresented: $isShowingReschedulePicker) {
                if let workOrder = workOrderToReschedule {
                    RescheduleView(workOrder: workOrder, isShowing: $isShowingReschedulePicker)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
            .alert(isPresented: $isShowingDeleteConfirmation) {
                Alert(
                    title: Text("Confirm Deletion"),
                    message: Text("Are you sure you want to delete this work order? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        isShowingDeleteSlider = true // Show slider after confirmation
                    },
                    secondaryButton: .cancel {
                        workOrderToDelete = nil // Reset state
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    private var displayedWorkOrders: [DisplayableWorkOrder] {
        return workOrders.map { workOrder in
            DisplayableWorkOrder(workOrder: workOrder, isHidden: false)
        }
    }
    
    private var workOrdersForSelectedDate: [DisplayableWorkOrder] {
        return displayedWorkOrders.filter { displayableOrder in
            if let workOrderDate = displayableOrder.workOrder.date {
                return Calendar.current.isDate(workOrderDate, inSameDayAs: selectedDate)
            }
            return false
        }
    }
    
    private func deleteWorkOrder(at workOrder: WorkOrder) {
        viewContext.delete(workOrder)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting work order: \(error.localizedDescription)")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func sendConfirmationMessage(to workOrder: WorkOrder) {
        guard let customerPhone = workOrder.customer?.phoneNumber else { return }
        
        let firstName = workOrder.customer?.name?.split(separator: " ").first ?? "Customer"
        let workOrderDate = formattedDate(workOrder.date ?? Date())
        let workOrderTime = formattedTime(workOrder.time ?? Date())
        
        let messageBody = "Hello \(firstName), your appointment for \(workOrder.category ?? "service") is scheduled on \(workOrderDate) at \(workOrderTime)."
        
        if let url = URL(string: "sms:\(customerPhone)&body=\(messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func statusColor(for status: String?) -> Color {
        switch status?.lowercased() {
        case "open": return .red
        case "completed": return .green
        case "incomplete": return .yellow
        default: return .gray
        }
    }
    private func confirmDelete(workOrder: WorkOrder) {
        workOrderToDelete = workOrder
        isShowingDeleteConfirmation = true
    }
    
    private func finalizeDelete() {
        guard let workOrder = workOrderToDelete else { return }
        
        // Add the deleted work order to the recently deleted items
        let deletedItem = DeletedItem(
            id: UUID(), // Generate a new UUID
            type: .workOrder,
            description: "Work Order #\(workOrder.workOrderNumber)",
            originalDate: workOrder.date,
            originalStatus: workOrder.status,
            originalCustomerName: workOrder.customer?.name,
            originalCategory: workOrder.category,
            originalTradesmen: (workOrder.tradesmen as? Set<Tradesmen>)?.compactMap { $0.name }
        )
        deletedItemsManager.addDeletedItem(deletedItem)
        
        // Delete the work order from Core Data
        viewContext.delete(workOrder)
        do {
            try viewContext.save()
            workOrderToDelete = nil // Reset state
        } catch {
            print("Error deleting work order: \(error.localizedDescription)")
        }
        isShowingDeleteSlider = false
    }
}

    // Coordinator to manage FSCalendar's Delegate and DataSource
class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    var parent: CalendarView

    @AppStorage("isDarkMode") private var isDarkMode: Bool = true

    init(_ parent: CalendarView) {
        self.parent = parent
    }

    // When a date is selected, update the selectedDate binding and show the modal
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        parent.selectedDate = date
    }

    // Add event markers (dots) for dates with work orders
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let workOrdersForDate = parent.workOrders.filter {
            Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
        }
        return workOrdersForDate.isEmpty ? 0 : 1  // Display a dot if there's a work order
    }

    // Customize the appearance of text for dates
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        return isDarkMode ? .white : .black // Adjust date text color dynamically
    }

    // Customize the appearance of event dots for specific dates (set to orange)
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        let workOrdersForDate = parent.workOrders.filter {
            Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
        }
        return workOrdersForDate.isEmpty ? nil : [.orange] // Show orange dots for work orders
    }
}


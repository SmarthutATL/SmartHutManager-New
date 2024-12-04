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
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel  // Access user role information
    
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
    
    var body: some View {
        NavigationView {
            VStack {
                // Toolbar (only visible for admins)
                if authViewModel.userRole == "admin" {
                    HStack {
                        // View Work Orders Button (Icon: Clipboard)
                        Button(action: {
                            DispatchQueue.main.async {
                                isPresentingWorkOrderList.toggle()
                            }
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
                        
                        // New Work Order Button (Blue Plus)
                        Button(action: {
                            DispatchQueue.main.async {
                                isPresentingNewWorkOrder.toggle()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title)
                        }
                        .sheet(isPresented: $isPresentingNewWorkOrder) {
                            NewWorkOrderView(selectedDate: selectedDate) // Pass selected date here
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
                    workOrders: displayedWorkOrders.map { $0.workOrder },  // Pass only visible work orders
                    isPresentingNewWorkOrder: $isPresentingNewWorkOrder
                )
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
                                            // Customer Name
                                            if let customerName = displayableOrder.workOrder.customer?.name {
                                                Text(customerName)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            } else {
                                                Text("Unknown")
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            }
                                            
                                            // Work order number directly beside the name
                                            Text("#\(displayableOrder.workOrder.workOrderNumber)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                        
                                        // Work order category (task)
                                        Text(displayableOrder.workOrder.category ?? "No Category")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                        
                                        // Status with color based on status value
                                        Text("Status: \(displayableOrder.workOrder.status ?? "No Status")")
                                            .font(.caption)
                                            .foregroundColor(statusColor(for: displayableOrder.workOrder.status))
                                        
                                        // Arrival Time
                                        if let workOrderTime = displayableOrder.workOrder.time {
                                            Text("Arrival Time: \(formattedTime(workOrderTime))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        // Display the tradesmen (from Core Data relationship)
                                        if let tradesmenSet = displayableOrder.workOrder.tradesmen as? Set<Tradesmen>, !tradesmenSet.isEmpty {
                                            let tradesmenNames = tradesmenSet.compactMap { $0.name }.joined(separator: ", ")
                                            Text("Technician(s): \(tradesmenNames)")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                                
                                // Reschedule Button (Only for admin)
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
                                            .scaleEffect(isShowingReschedulePicker ? 1.1 : 1.0)
                                            .animation(.easeInOut, value: isShowingReschedulePicker)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.leading, 10)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if authViewModel.userRole == "admin" {
                                    // Delete Button (Only for admin)
                                    Button(role: .destructive) {
                                        deleteWorkOrder(at: displayableOrder.workOrder)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    // Send Message Button
                                    Button {
                                        sendConfirmationMessage(to: displayableOrder.workOrder)
                                    } label: {
                                        Label("Message", systemImage: "message.fill")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .sheet(isPresented: $isShowingReschedulePicker) {
                if let workOrder = workOrderToReschedule {
                    RescheduleView(workOrder: workOrder, isShowing: $isShowingReschedulePicker)
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }
    
    // MARK: - Displayed Work Orders
    private var displayedWorkOrders: [DisplayableWorkOrder] {
        // Make all work orders visible without hiding any
        return workOrders.map { workOrder in
            DisplayableWorkOrder(workOrder: workOrder, isHidden: false)
        }
    }

    // MARK: - Work Orders for Selected Date
    private var workOrdersForSelectedDate: [DisplayableWorkOrder] {
        return displayedWorkOrders.filter { displayableOrder in
            if let workOrderDate = displayableOrder.workOrder.date {
                return Calendar.current.isDate(workOrderDate, inSameDayAs: selectedDate)
            }
            return false
        }
    }

    // MARK: - Helper Functions
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
        guard let customerPhone = workOrder.customer?.phoneNumber else {
            print("Customer phone number not available")
            return
        }

        let firstName = workOrder.customer?.name?.split(separator: " ").first ?? "Customer"
        let workOrderDate = formattedDate(workOrder.date ?? Date())
        let workOrderTime = formattedTime(workOrder.time ?? Date())

        let messageBody = """
        Hello \(firstName), your appointment for \(workOrder.category ?? "service") is scheduled on \(workOrderDate) at \(workOrderTime).
        """

        if let url = URL(string: "sms:\(customerPhone)&body=\(messageBody.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        } else {
            print("Failed to create message URL")
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
}
// MARK: - Reschedule View
struct RescheduleView: View {
    @ObservedObject var workOrder: WorkOrder
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isShowing: Bool
    
    // Track the selected date and time for rescheduling
    @State private var newDate: Date
    @State private var newTime: Date
    
    init(workOrder: WorkOrder, isShowing: Binding<Bool>) {
        self.workOrder = workOrder
        self._isShowing = isShowing
        // Initialize with the current work order's date and time if they exist
        _newDate = State(initialValue: workOrder.date ?? Date())
        _newTime = State(initialValue: workOrder.time ?? Date())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Date Picker for the new date
                DatePicker(
                    "Reschedule Date",
                    selection: $newDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()

                // Modern Time Picker for the new time
                VStack(alignment: .leading) {
                    Text("Reschedule Time")
                        .font(.headline)
                        .foregroundColor(.gray)
                    DatePicker("", selection: $newTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                }
                .padding([.leading, .trailing])

                Spacer()

                // Save button to persist changes
                Button(action: {
                    // Combine the new date and time, update both, and save
                    workOrder.date = combineDateWithTime(date: newDate, time: newTime)
                    workOrder.time = newTime // Save the new time separately
                    do {
                        try viewContext.save()
                        isShowing = false
                    } catch {
                        print("Error saving rescheduled date and time: \(error.localizedDescription)")
                    }
                }) {
                    Text("Save New Date & Time")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                }
                .padding([.horizontal, .bottom], 20)
            }
            .navigationTitle("Reschedule Work Order")
            .navigationBarItems(trailing: Button("Cancel") {
                isShowing = false
            })
        }
    }

    // Helper function to combine date and time
    private func combineDateWithTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: timeComponents.hour ?? 0, minute: timeComponents.minute ?? 0, second: 0, of: date) ?? date
    }
}

// FSCalendar SwiftUI Wrapper for Day, Week, and Month views
struct CalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date
    @Binding var calendarScope: FSCalendarScope // Track the scope (day, week, or month)
    var workOrders: [WorkOrder] // Pass work orders for event markers
    @Binding var isPresentingNewWorkOrder: Bool // To trigger new work order modal

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()

        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Customize appearance
        calendar.appearance.headerTitleColor = .white
        calendar.appearance.weekdayTextColor = .white
        calendar.appearance.titleDefaultColor = .white
        calendar.appearance.titleTodayColor = .white // Make the text white for the current day with the red circle
        calendar.appearance.selectionColor = .blue // Red circle for the selected day
        calendar.appearance.eventDefaultColor = .orange // Set the dot color to orange for work orders

        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.scope = calendarScope
        uiView.reloadData()  // Reload the calendar data when updating the scope
    }

    // Coordinator to manage FSCalendar's Delegate and DataSource
    class Coordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
        var parent: CalendarView

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
                // Match work orders for the specific date
                Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
            }
            return workOrdersForDate.isEmpty ? 0 : 1  // Display a dot if there's a work order
        }

        // Customize the appearance of event dots for specific dates (set to orange)
        func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
            let workOrdersForDate = parent.workOrders.filter {
                Calendar.current.isDate($0.date ?? Date(), inSameDayAs: date)
            }
            return workOrdersForDate.isEmpty ? nil : [.orange] // Show orange dots for work orders
        }
    }
}

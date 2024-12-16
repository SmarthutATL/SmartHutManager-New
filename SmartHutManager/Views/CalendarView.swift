import SwiftUI
import FSCalendar


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
}

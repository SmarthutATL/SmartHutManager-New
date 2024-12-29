import SwiftUI
import FSCalendar

// FSCalendar SwiftUI Wrapper for Day, Week, and Month views
struct CalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date
    @Binding var calendarScope: FSCalendarScope // Track the scope (day, week, or month)
    var workOrders: [WorkOrder] // Pass work orders for event markers
    @Binding var isPresentingNewWorkOrder: Bool // To trigger new work order modal
    @Binding var isDarkMode: Bool // Track dark mode state dynamically

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> FSCalendar {
        let calendar = FSCalendar()
        
        calendar.delegate = context.coordinator
        calendar.dataSource = context.coordinator
        
        // Initial appearance customization
        updateAppearance(for: calendar)
        
        return calendar
    }

    func updateUIView(_ uiView: FSCalendar, context: Context) {
        uiView.scope = calendarScope
        updateAppearance(for: uiView) // Update appearance dynamically
        uiView.reloadData() // Reload the calendar data to apply changes
    }

    private func updateAppearance(for calendar: FSCalendar) {
        // Set colors dynamically based on light/dark mode
        calendar.appearance.headerTitleColor = isDarkMode ? .white : .black
        calendar.appearance.weekdayTextColor = isDarkMode ? .white : .black
        calendar.appearance.titleDefaultColor = isDarkMode ? .white : .black
        calendar.appearance.titleTodayColor = isDarkMode ? .white : .black
        calendar.appearance.selectionColor = .blue
        calendar.appearance.eventDefaultColor = .orange
        calendar.backgroundColor = isDarkMode ? .black : .white
    }
}

import SwiftUI

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

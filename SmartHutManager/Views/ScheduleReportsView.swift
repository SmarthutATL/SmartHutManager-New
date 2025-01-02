import SwiftUI

enum ReportFrequency: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct ScheduleReportsView: View {
    var onSchedule: (ReportFrequency) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFrequency: ReportFrequency = .weekly

    var body: some View {
        NavigationView {
            Form {
                Picker("Frequency", selection: $selectedFrequency) {
                    ForEach(ReportFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
            }
            .navigationTitle("Schedule Report")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        onSchedule(selectedFrequency)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

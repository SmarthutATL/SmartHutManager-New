import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alertViewModel: AlertViewModel

    var body: some View {
        NavigationView {
            VStack {
                if alertViewModel.alerts.isEmpty {
                    emptyStateView
                } else {
                    alertsListView
                }

                if !alertViewModel.alerts.isEmpty {
                    clearAllButton
                }
            }
            .navigationTitle("Alerts")
        }
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Alerts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
                .padding(.top, 8)
            Text("You're all caught up!")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.top, 4)
            Spacer()
        }
        .padding()
    }

    // MARK: - Alerts List View
    private var alertsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(alertViewModel.alerts.indices, id: \.self) { index in
                    AlertCardView(alert: alertViewModel.alerts[index])
                        .contextMenu {
                            Button("Mark as Read") {
                                alertViewModel.alerts[index].isNew = false
                                alertViewModel.saveContext()
                            }
                            Button("Delete") {
                                alertViewModel.removeAlert(at: index)
                            }
                        }
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Clear All Button
    private var clearAllButton: some View {
        Button(action: {
            alertViewModel.clearAllAlerts()
        }) {
            Text("Clear All")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alertViewModel: AlertViewModel

    var body: some View {
        NavigationView {
            VStack {
                if alertViewModel.alerts.isEmpty {
                    // Empty State View
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
                } else {
                    // List of Alerts
                    List {
                        ForEach(alertViewModel.alerts.indices, id: \.self) { index in
                            HStack {
                                Text(alertViewModel.alerts[index])
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        .onDelete(perform: removeAlert)
                    }
                    .listStyle(PlainListStyle())
                }

                // Clear All Button
                if !alertViewModel.alerts.isEmpty {
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
                            .padding()
                    }
                }
            }
            .navigationTitle("Alerts")
        }
    }

    private func removeAlert(at offsets: IndexSet) {
        offsets.forEach { index in
            alertViewModel.removeAlert(at: index)
        }
    }
}

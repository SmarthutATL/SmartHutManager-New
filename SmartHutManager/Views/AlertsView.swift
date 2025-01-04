import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var alertViewModel: AlertViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(alertViewModel.alerts.indices, id: \.self) { index in
                    HStack {
                        Text(alertViewModel.alerts[index])
                        Spacer()
                        Button(action: {
                            alertViewModel.removeAlert(at: index)
                        }) {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Alerts")
        }
    }
}

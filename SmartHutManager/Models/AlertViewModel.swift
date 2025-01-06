import Foundation

class AlertViewModel: ObservableObject {
    @Published var alerts: [String] = []
    @Published var alertMessage: String = " "
    @Published var hasNewAlert: Bool = false
    @Published var alertCount: Int = 0 // Add this property

    func addAlert(_ alert: String) {
        alerts.append(alert)
        alertCount = alerts.count // Update the alert count
        hasNewAlert = true
        print("Alert added: \(alert), hasNewAlert: \(hasNewAlert)")
    }

    func removeAlert(at index: Int) {
        alerts.remove(at: index)
        alertCount = alerts.count // Update the alert count
        if alerts.isEmpty {
            hasNewAlert = false // No more new alerts
        }
    }

    func markAlertsAsRead() {
        hasNewAlert = false
    }

    func clearAllAlerts() {
        alerts.removeAll()
        alertCount = 0 // Reset the alert count
        hasNewAlert = false
    }
}

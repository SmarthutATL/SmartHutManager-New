import Foundation

class AlertViewModel: ObservableObject {
    @Published var alerts: [String] = []
    @Published var alertMessage: String = " "
    @Published var hasNewAlert: Bool = false // Add this property

    var alertCount: Int {
        alerts.count
    }
    
    func addAlert(_ alert: String) {
        alerts.append(alert)
        hasNewAlert = true // Mark as new alert
    }
    
    func removeAlert(at index: Int) {
        alerts.remove(at: index)
        if alerts.isEmpty {
            hasNewAlert = false // No more new alerts
        }
    }
    
    func markAlertsAsRead() {
        hasNewAlert = false // Reset new alert indicator
        alerts.removeAll()
    }
   
func clearAllAlerts() {
        alerts.removeAll()
        hasNewAlert = false
    }
}

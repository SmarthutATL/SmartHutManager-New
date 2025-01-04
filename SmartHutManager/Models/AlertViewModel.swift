import Foundation

class AlertViewModel: ObservableObject {
    @Published var alerts: [String] = []
    @Published var alertMessage: String = " "
    
    var alertCount: Int {
        alerts.count
    }
    
    func addAlert(_ alert: String) {
        alerts.append(alert)
    }
    
    func removeAlert(at index: Int) {
        alerts.remove(at: index)
    }
}

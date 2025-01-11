import Foundation
import CoreData

class AlertViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    @Published var alerts: [AppAlert] = [] // CoreData-based alerts
    @Published var hasNewAlert: Bool = false
    @Published var alertCount: Int = 0

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAlerts()
    }

    // MARK: - Fetch Alerts
    func fetchAlerts() {
        let request: NSFetchRequest<AppAlert> = AppAlert.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            alerts = try context.fetch(request)
            alertCount = alerts.count
            hasNewAlert = alerts.contains { $0.isNew }
        } catch {
            print("Failed to fetch alerts: \(error)")
        }
    }

    // MARK: - Add Alert
    func addAlert(_ message: String) {
        let newAlert = AppAlert(context: context)
        newAlert.id = UUID()
        newAlert.message = message
        newAlert.isNew = true
        newAlert.timestamp = Date()

        saveContext()
        fetchAlerts()
    }

    // MARK: - Mark Alerts as Read
    func markAlertsAsRead() {
        alerts.forEach { $0.isNew = false }
        saveContext()
        fetchAlerts()
    }

    // MARK: - Clear All Alerts
    func clearAllAlerts() {
        alerts.forEach { context.delete($0) }
        saveContext()
        fetchAlerts()
    }

    // MARK: - Remove Alert
    func removeAlert(at index: Int) {
        guard alerts.indices.contains(index) else { return }
        context.delete(alerts[index])
        saveContext()
        fetchAlerts()
    }

    // MARK: - Save Context
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}

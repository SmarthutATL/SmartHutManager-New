import CoreData
import Combine

class PersistenceController {
    static let shared = PersistenceController()
    private var autosaveCancellable: AnyCancellable?
    private var saveWorkItem: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.smarthutmanager.saveQueue", qos: .background)
    private let saveThrottleInterval: TimeInterval = 5  // Throttle saves to reduce energy consumption

    // Use `var` for container
    var container: NSPersistentContainer

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Pre-fill with sample data for preview
        let customer = Customer(context: viewContext)
        customer.name = "John Doe"

        let workOrder = WorkOrder(context: viewContext)
        workOrder.category = "Home Automation"
        workOrder.date = Date()
        workOrder.photos = ["photo1", "photo2"]
        customer.addToWorkOrders(workOrder)

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SmartHutManager")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Successfully loaded store: \(storeDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        startAutosaving(interval: 30)
    }

    deinit {
        autosaveCancellable?.cancel()
    }

    // MARK: - Start Autosave (Reduces background work)
    private func startAutosaving(interval: TimeInterval) {
        autosaveCancellable = Timer.publish(every: interval, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.throttledSaveContext()
        }
    }

    // MARK: - Throttled Save Context (Delays saves to reduce energy usage)
    func throttledSaveContext() {
        saveWorkItem?.cancel()
        saveWorkItem = DispatchWorkItem { [weak self] in
            self?.saveContext()
        }
        saveQueue.asyncAfter(deadline: .now() + saveThrottleInterval, execute: saveWorkItem!)
    }

    // MARK: - Save Context (Only saves if there are changes)
    private func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            print("Context saved successfully.")
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }
}

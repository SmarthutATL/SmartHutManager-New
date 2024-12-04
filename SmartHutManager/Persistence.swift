import CoreData
import Combine
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()
    private var autosaveCancellable: AnyCancellable?
    private var saveWorkItem: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.smarthutmanager.saveQueue", qos: .background)
    private let saveThrottleInterval: TimeInterval = 2  // 2 seconds debounce interval

    // Preview setup for SwiftUI previews
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

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SmartHutManager")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }

        let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.SmartHutATL.SmartHutManager")
        cloudKitOptions.databaseScope = .shared
        description.cloudKitContainerOptions = cloudKitOptions

        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Successfully loaded store: \(storeDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePersistentStoreRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )

        startAutosaving(interval: 15)
    }

    // Autosave function
    private func startAutosaving(interval: TimeInterval) {
        autosaveCancellable = Timer.publish(every: interval, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.throttledSaveContext()
        }
    }

    deinit {
        autosaveCancellable?.cancel()
    }

    // MARK: - Throttled Save Context
    func throttledSaveContext() {
        saveWorkItem?.cancel()
        saveWorkItem = DispatchWorkItem { [weak self] in
            self?.saveContext()
        }
        saveQueue.asyncAfter(deadline: .now() + saveThrottleInterval, execute: saveWorkItem!)
    }

    // MARK: - Save Context (Handles Save with Logging)
    private func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully.")
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Handle CloudKit Sync and Background Fetch
    @objc private func handlePersistentStoreRemoteChange(_ notification: Notification) {
        print("Persistent store remote change received.")
        let context = container.viewContext
        context.performAndWait {
            do {
                try context.setQueryGenerationFrom(.current)
                if context.hasChanges {
                    try context.save()
                    print("Context saved after remote change.")
                } else {
                    print("No changes detected in context.")
                }
            } catch {
                print("Failed to process remote change notification: \(error)")
            }
        }
    }

    func performBackgroundSync() {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.perform {
            do {
                try backgroundContext.save()
                print("Background sync successful.")
            } catch {
                print("Failed to sync in the background: \(error)")
            }
        }
    }

    // MARK: - Sharing Data with CKShare
    func shareRecord(_ object: NSManagedObject, completion: @escaping (CKShare?, Error?) -> Void) {
        let context = container.viewContext
        let objectID = object.objectID

        context.perform {
            do {
                // Create a new CKRecord for the object
                let recordID = CKRecord.ID(recordName: objectID.uriRepresentation().absoluteString)
                let record = CKRecord(recordType: object.entity.name!, recordID: recordID)
                
                // Populate the CKRecord with data from the object
                self.populateCKRecord(record, from: object)
                
                // Create a CKShare associated with the CKRecord
                let share = CKShare(rootRecord: record)
                share.publicPermission = .readWrite // Allow everyone to read and write
                
                // Prepare the CKModifyRecordsOperation to save the CKShare
                let operation = CKModifyRecordsOperation(recordsToSave: [record, share])
                operation.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success:
                        print("Record shared successfully.")
                        completion(share, nil)
                    case .failure(let error):
                        print("Error sharing record: \(error.localizedDescription)")
                        completion(nil, error)
                    }
                }
                
                // Execute the operation on the shared CloudKit database
                CKContainer.default().sharedCloudDatabase.add(operation)
            }
        }
    }

    // Helper to populate CKRecord with data from NSManagedObject
    private func populateCKRecord(_ record: CKRecord, from object: NSManagedObject) {
        for (key, _) in object.entity.attributesByName {
            if let value = object.value(forKey: key) as? CKRecordValue {
                record[key] = value
            }
        }
    }
}

import CoreData
import Combine
import CloudKit

class PersistenceController {
    static let shared = PersistenceController()
    private var autosaveCancellable: AnyCancellable?
    private var saveWorkItem: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "com.smarthutmanager.saveQueue", qos: .background)
    private let saveThrottleInterval: TimeInterval = 5  // Throttle saves to reduce energy consumption

    let container: NSPersistentCloudKitContainer

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

        container.loadPersistentStores { storeDescription, error in
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

    // MARK: - Handle CloudKit Sync & Background Fetch (Efficient energy use)
    @objc private func handlePersistentStoreRemoteChange(_ notification: Notification) {
        print("Persistent store remote change received.")
        
        let context = container.viewContext
        context.perform {
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

    // MARK: - Perform Background Sync (Runs on new background context)
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

    // MARK: - Share Data with CKShare (Reduces CloudKit impact)
    func shareRecord(_ object: NSManagedObject, completion: @escaping (CKShare?, Error?) -> Void) {
        let context = container.viewContext
        let objectID = object.objectID

        context.perform {
            do {
                let recordID = CKRecord.ID(recordName: objectID.uriRepresentation().absoluteString)
                let record = CKRecord(recordType: object.entity.name!, recordID: recordID)
                self.populateCKRecord(record, from: object)
                
                let share = CKShare(rootRecord: record)
                share.publicPermission = .readWrite
                
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
                
                CKContainer.default().sharedCloudDatabase.add(operation)
            }
        }
    }

    // Populate CKRecord with Data
    private func populateCKRecord(_ record: CKRecord, from object: NSManagedObject) {
        for (key, _) in object.entity.attributesByName {
            if let value = object.value(forKey: key) as? CKRecordValue {
                record[key] = value
            }
        }
    }
}

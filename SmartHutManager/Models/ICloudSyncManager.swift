import Foundation
import CoreData
import CloudKit

// MARK: - iCloud Sync Manager
class ICloudSyncManager {
    private let persistentContainer: NSPersistentCloudKitContainer
    private var isSyncInProgress = false
    private var syncDebounceTimer: Timer?
    private var lastSyncTime: Date?
    private let syncThrottleInterval: TimeInterval = 60  // Minimum 60 seconds between syncs

    init(persistentContainer: NSPersistentCloudKitContainer) {
        self.persistentContainer = persistentContainer
        setupICloudChangeListener()
    }

    private func setupICloudChangeListener() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitChanges(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: persistentContainer.persistentStoreCoordinator
        )
    }

    @objc private func handleCloudKitChanges(_ notification: Notification) {
        guard !isSyncInProgress else {
            print("Sync already in progress, skipping new sync request.")
            return
        }

        syncDebounceTimer?.invalidate()
        syncDebounceTimer = Timer.scheduledTimer(withTimeInterval: syncThrottleInterval, repeats: false) { [weak self] _ in
            self?.performSync()
        }
    }

    private func performSync() {
        guard !isSyncInProgress else {
            print("Sync is already in progress, avoiding duplicate sync.")
            return
        }

        isSyncInProgress = true
        let viewContext = persistentContainer.viewContext

        viewContext.perform {
            do {
                try viewContext.setQueryGenerationFrom(.current)
                viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                if viewContext.hasChanges {
                    try viewContext.save()
                    self.lastSyncTime = Date()
                    print("Changes saved and synced with iCloud.")
                } else {
                    print("No changes detected, skipping sync.")
                }

                self.finishSync()

            } catch {
                self.logError(error, context: "performSync()")
                self.finishSync()
            }
        }
    }

    private func finishSync() {
        isSyncInProgress = false
        print("Sync finished successfully.")
    }

    private func logError(_ error: Error, context: String) {
        let nsError = error as NSError
        print("Error in \(context): \(nsError), \(nsError.userInfo)")
    }

    // MARK: - Assign to a Custom Record Zone
    func assignToRecordZone(completion: @escaping (Error?) -> Void) {
        let context = persistentContainer.viewContext

        context.perform {
            do {
                // Fetch all JobCategoryEntity instances
                let fetchRequest = NSFetchRequest<JobCategoryEntity>(entityName: "JobCategoryEntity")
                let jobCategories = try context.fetch(fetchRequest)

                for jobCategory in jobCategories {
                    let record = CKRecord(recordType: "JobCategoryEntity", recordID: CKRecord.ID(recordName: jobCategory.objectID.uriRepresentation().absoluteString))
                    record["name"] = jobCategory.name as CKRecordValue?

                    // Create a custom zone
                    let customZoneID = CKRecordZone.ID(zoneName: "CustomZone", ownerName: CKCurrentUserDefaultName)
                    let customZone = CKRecordZone(zoneID: customZoneID)
                    
                    // Add to the private CloudKit database
                    let privateDatabase = CKContainer.default().privateCloudDatabase

                    let zoneCreationOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: nil)
                    zoneCreationOperation.modifyRecordZonesResultBlock = { result in
                        switch result {
                        case .success:
                            print("Custom zone created successfully.")
                            // Save records to the custom zone
                            self.saveRecordToZone(record: record, database: privateDatabase, completion: completion)
                        case .failure(let error):
                            print("Error creating custom zone: \(error)")
                            completion(error)
                        }
                    }
                    privateDatabase.add(zoneCreationOperation)
                }
            } catch {
                print("Failed to fetch JobCategoryEntity objects: \(error)")
                completion(error)
            }
        }
    }

    private func saveRecordToZone(record: CKRecord, database: CKDatabase, completion: @escaping (Error?) -> Void) {
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                print("Record successfully saved to custom zone.")
                completion(nil)
            case .failure(let error):
                print("Error saving record to custom zone: \(error)")
                completion(error)
            }
        }
        database.add(operation)
    }
}

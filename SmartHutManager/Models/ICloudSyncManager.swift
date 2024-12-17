import Foundation
import CoreData

// MARK: - iCloud Sync Manager (Handles sync updates)
class ICloudSyncManager {
    private let persistentContainer: NSPersistentCloudKitContainer
    private var isSyncInProgress = false
    private var syncWorkItem: DispatchWorkItem?
    private var lastSyncTime: Date?
    private let syncThrottleInterval: TimeInterval = 60  // Minimum 60 seconds between syncs
    private let syncQueue = DispatchQueue(label: "com.smarthut.syncQueue", qos: .background)

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

        syncWorkItem?.cancel()

        let timeSinceLastSync = lastSyncTime.map { Date().timeIntervalSince($0) } ?? syncThrottleInterval
        guard timeSinceLastSync >= syncThrottleInterval else {
            print("Sync request ignored due to throttle interval.")
            return
        }

        syncWorkItem = DispatchWorkItem { [weak self] in
            self?.performSync()
        }

        syncQueue.asyncAfter(deadline: .now() + syncThrottleInterval, execute: syncWorkItem!)
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
                print("Error handling CloudKit changes: \(error.localizedDescription)")
                self.finishSync()
            }
        }
    }

    private func finishSync() {
        isSyncInProgress = false
        print("Sync finished successfully.")
    }
}

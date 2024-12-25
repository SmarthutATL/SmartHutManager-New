import Foundation
import CoreData

// MARK: - iCloud Sync Manager (Handles sync updates)
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
}

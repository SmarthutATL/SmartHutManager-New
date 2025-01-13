import Foundation
import CoreData
import FirebaseFirestore

// MARK: - Firebase Sync Manager
class FirebaseSyncManager {
    private let firestore = Firestore.firestore()
    private let persistentContainer: NSPersistentContainer

    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }

    // MARK: - Fetch Data from Firebase and Sync with Core Data
    func syncFromFirebase(collection: String) {
        firestore.collection(collection).getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let documents = snapshot?.documents else {
                print("Error fetching Firestore documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let context = self.persistentContainer.viewContext
            context.perform {
                for document in documents {
                    self.updateOrCreateEntity(from: document, context: context)
                }

                do {
                    try context.save()
                    print("Core Data synced with Firebase successfully.")
                } catch {
                    print("Failed to save context: \(error.localizedDescription)")
                }
            }
        }
    }

    private func updateOrCreateEntity(from document: QueryDocumentSnapshot, context: NSManagedObjectContext) {
        guard let entityName = document.data()["entityName"] as? String else {
            print("Missing entity name for document: \(document.documentID)")
            return
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "id == %@", document.documentID)

        do {
            if let existingEntity = try context.fetch(fetchRequest).first as? NSManagedObject {
                // Skip updates for admin roles (example)
                if let role = existingEntity.value(forKey: "role") as? String, role == "admin" {
                    print("Skipping update for admin entity: \(document.documentID)")
                    return
                }

                // Update only if values have changed
                for (key, value) in document.data() {
                    if let existingValue = existingEntity.value(forKey: key), "\(existingValue)" == "\(value)" {
                        continue // Skip if the value hasn't changed
                    }
                    existingEntity.setValue(value, forKey: key)
                }
            } else {
                // Create new entity
                let newEntity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                for (key, value) in document.data() {
                    newEntity.setValue(value, forKey: key)
                }
            }
        } catch {
            print("Error updating/creating entity for document \(document.documentID): \(error.localizedDescription)")
        }
    }

    // MARK: - Push Core Data Changes to Firebase
    func syncToFirebase(entityName: String, collection: String) {
        let context = persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        do {
            let objects = try context.fetch(fetchRequest) as? [NSManagedObject]
            for object in objects ?? [] {
                saveToFirestore(object: object, collection: collection)
            }
        } catch {
            print("Error fetching Core Data objects: \(error.localizedDescription)")
        }
    }

    private func saveToFirestore(object: NSManagedObject, collection: String) {
        var data: [String: Any] = [:]
        for (key, _) in object.entity.attributesByName {
            data[key] = object.value(forKey: key)
        }

        let documentID = object.value(forKey: "id") as? String ?? UUID().uuidString
        firestore.collection(collection).document(documentID).setData(data) { error in
            if let error = error {
                print("Error saving to Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully synced \(object.entity.name ?? "unknown entity") to Firestore.")
            }
        }
    }
}

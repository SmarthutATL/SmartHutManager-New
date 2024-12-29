import SwiftUI
import Combine
import FirebaseFirestore

class DeletedItemsManager: ObservableObject {
    @Published var recentlyDeletedItems: [DeletedItem] = [] {
        didSet {
            saveToFirebase()
        }
    }

    private let db = Firestore.firestore()

    init() {
        loadFromFirebase()
    }

    // Add a deleted item to the list
    func addDeletedItem(_ item: DeletedItem) {
        recentlyDeletedItems.append(item)
        saveToFirebase()
    }

    // Remove a deleted item by ID
    func removeDeletedItem(withId id: UUID) {
        recentlyDeletedItems.removeAll { $0.id == id }
        deleteFromFirebase(id: id)
    }

    // Clear all deleted items
    func clearAll() {
        recentlyDeletedItems.removeAll()
        deleteAllFromFirebase()
    }

    // MARK: - Firebase Persistence

    private func saveToFirebase() {
        for item in recentlyDeletedItems {
            let docRef = db.collection("recentlyDeletedItems").document(item.id.uuidString)

            docRef.setData([
                "id": item.id.uuidString,
                "type": item.type.rawValue,
                "description": item.description,
                "originalDate": item.originalDate?.timeIntervalSince1970 ?? NSNull(),
                "originalStatus": item.originalStatus ?? NSNull()
            ]) { error in
                if let error = error {
                    print("Error saving to Firebase: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadFromFirebase() {
        db.collection("recentlyDeletedItems").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading from Firebase: \(error.localizedDescription)")
                return
            }

            self.recentlyDeletedItems = snapshot?.documents.compactMap { doc in
                let data = doc.data()

                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let typeString = data["type"] as? String,
                      let type = DeletedItemType(rawValue: typeString),
                      let description = data["description"] as? String else {
                    return nil
                }

                return DeletedItem(
                    id: id,
                    type: type,
                    description: description,
                    originalDate: (data["originalDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) },
                    originalStatus: data["originalStatus"] as? String
                )
            } ?? []
        }
    }

    private func deleteFromFirebase(id: UUID) {
        db.collection("recentlyDeletedItems").document(id.uuidString).delete { error in
            if let error = error {
                print("Error deleting from Firebase: \(error.localizedDescription)")
            }
        }
    }

    private func deleteAllFromFirebase() {
        db.collection("recentlyDeletedItems").getDocuments { snapshot, error in
            if let error = error {
                print("Error clearing Firebase: \(error.localizedDescription)")
                return
            }

            snapshot?.documents.forEach { $0.reference.delete() }
        }
    }
}

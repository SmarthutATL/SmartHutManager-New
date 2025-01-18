//
//  SupportManager.swift
//  SmartHutManager
//
//  Created by Darius Ogletree on 1/17/25.
//

import Foundation
import FirebaseFirestore

class SupportManager {
    static let shared = SupportManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    func saveTicketToFirestore(description: String, priority: String) {
        db.collection("support_tickets").addDocument(data: [
            "description": description,
            "priority": priority,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error saving ticket: \(error.localizedDescription)")
            } else {
                print("Ticket saved successfully.")
            }
        }
    }
}

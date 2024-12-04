import SwiftUI
import CoreData
import FirebaseFirestore
import Foundation

class TradesmenManager {
    static let shared = TradesmenManager()
    
    private let firestore = Firestore.firestore()
    
    // MARK: - Sync Tradesmen from Firestore to Core Data
    func syncTradesmen(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        firestore.collection("tradesmen").getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(nil)
                return
            }
            
            // Fetch existing tradesmen from Core Data to avoid duplicates
            let existingTradesmen = self.fetchTradesmen(context: context)
            
            context.perform {
                for document in documents {
                    let data = document.data()
                    
                    // Parse data from Firestore document
                    guard let name = data["name"] as? String,
                          let jobTitle = data["jobTitle"] as? String,
                          let phoneNumber = data["phoneNumber"] as? String,
                          let address = data["address"] as? String,
                          let email = data["email"] as? String,
                          let points = data["points"] as? Int,
                          let badges = data["badges"] as? [String],
                          let jobCompletionStreak = data["jobCompletionStreak"] as? Int else { continue }
                    
                    // Check if the tradesman already exists in Core Data
                    if !existingTradesmen.contains(where: { $0.name == name && $0.email == email }) {
                        // Add new tradesman to Core Data
                        let newTradesman = Tradesmen(context: context)
                        newTradesman.name = name
                        newTradesman.jobTitle = jobTitle
                        newTradesman.phoneNumber = phoneNumber
                        newTradesman.address = address
                        newTradesman.email = email
                        newTradesman.points = Int32(points)
                        newTradesman.badges = badges
                        newTradesman.jobCompletionStreak = Int32(jobCompletionStreak)
                    }
                }
                
                // Save the Core Data context
                do {
                    try context.save()
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        }
    }

    // MARK: - Fetch Tradesmen from Core Data
    func fetchTradesmen(context: NSManagedObjectContext) -> [Tradesmen] {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching tradesmen: \(error)")
            return []
        }
    }
    
    // MARK: - Add Points
    func addPoints(to tradesman: Tradesmen, points: Int, context: NSManagedObjectContext) {
        context.perform {
            tradesman.points += Int32(points)
            do {
                try context.save()
                print("Added \(points) points to \(tradesman.name ?? "Unknown"). Total points: \(tradesman.points)")
            } catch {
                print("Failed to save points: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Earn Badge
    func earnBadge(for tradesman: Tradesmen, badge: String, context: NSManagedObjectContext) {
        context.perform {
            if tradesman.badges == nil {
                tradesman.badges = []
            }
            if !(tradesman.badges?.contains(badge) ?? false) {
                tradesman.badges?.append(badge)
                print("Badge earned: \(badge) by \(tradesman.name ?? "Unknown")")
            }
            do {
                try context.save()
            } catch {
                print("Failed to save badge: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Update Job Completion Streak
    func updateJobCompletionStreak(for tradesman: Tradesmen, isSuccessful: Bool, context: NSManagedObjectContext) {
        context.perform {
            if isSuccessful {
                tradesman.jobCompletionStreak += 1
                if tradesman.jobCompletionStreak == 10 { // Example: Earn badge for 10 successful jobs
                    self.earnBadge(for: tradesman, badge: "10 Jobs Streak", context: context)
                }
            } else {
                tradesman.jobCompletionStreak = 0
            }
            do {
                try context.save()
                print("Updated streak to \(tradesman.jobCompletionStreak) for \(tradesman.name ?? "Unknown")")
            } catch {
                print("Failed to update job streak: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Save Tradesman to Firestore
    func saveTradesmanToFirestore(tradesman: Tradesmen) {
        let data: [String: Any] = [
            "name": tradesman.name ?? "",
            "jobTitle": tradesman.jobTitle ?? "",
            "phoneNumber": tradesman.phoneNumber ?? "",
            "address": tradesman.address ?? "",
            "email": tradesman.email ?? "",
            "points": tradesman.points,
            "badges": tradesman.badges ?? [],
            "jobCompletionStreak": tradesman.jobCompletionStreak
        ]
        
        firestore.collection("tradesmen").document(tradesman.name ?? UUID().uuidString).setData(data) { error in
            if let error = error {
                print("Failed to save tradesman to Firestore: \(error.localizedDescription)")
            } else {
                print("Tradesman saved to Firestore successfully.")
            }
        }
    }
}

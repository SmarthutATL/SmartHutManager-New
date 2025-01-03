import SwiftUI
import CoreData
import FirebaseFirestore
import Foundation

class TradesmenManager {
    static let shared = TradesmenManager()
    
    private let firestore = Firestore.firestore()
    
    // MARK: - Sync Tradesmen from Firestore to Core Data
    func syncTradesmen(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        let firestore = Firestore.firestore()
        
        firestore.collection("tradesmen").getDocuments { tradesmenSnapshot, tradesmenError in
            if let tradesmenError = tradesmenError {
                completion(tradesmenError)
                return
            }
            
            guard let tradesmenDocuments = tradesmenSnapshot?.documents else {
                completion(nil)
                return
            }
            
            // Fetch existing tradesmen from Core Data to avoid duplicates
            let existingTradesmen = self.fetchTradesmen(context: context)
            
            context.perform {
                for tradesmanDocument in tradesmenDocuments {
                    let tradesmanData = tradesmanDocument.data()
                    
                    // Parse basic data from Firestore tradesmen document
                    guard let email = tradesmanData["email"] as? String else {
                        print("Tradesman missing email, skipping...")
                        continue
                    }
                    
                    // Fetch additional user data from the `users` collection
                    firestore.collection("users").whereField("email", isEqualTo: email).getDocuments { userSnapshot, userError in
                        if let userError = userError {
                            print("Error fetching user data for email \(email): \(userError.localizedDescription)")
                            return
                        }
                        
                        guard let userDocument = userSnapshot?.documents.first else {
                            print("No matching user found for email: \(email)")
                            return
                        }
                        
                        let userData = userDocument.data()
                        let firstName = userData["firstName"] as? String ?? "Unknown Name"
                        let role = userData["role"] as? String ?? "Unknown Role"
                        
                        // Parse additional tradesman data
                        let jobTitle = tradesmanData["jobTitle"] as? String ?? role
                        let phoneNumber = tradesmanData["phoneNumber"] as? String
                        let address = tradesmanData["address"] as? String
                        let points = tradesmanData["points"] as? Int ?? 0
                        let badges = tradesmanData["badges"] as? [String] ?? []
                        let jobCompletionStreak = tradesmanData["jobCompletionStreak"] as? Int ?? 0
                        
                        // Check if the tradesman already exists in Core Data
                        if !existingTradesmen.contains(where: { $0.email == email }) {
                            // Add new tradesman to Core Data
                            let newTradesman = Tradesmen(context: context)
                            newTradesman.name = firstName
                            newTradesman.jobTitle = jobTitle
                            newTradesman.phoneNumber = phoneNumber
                            newTradesman.address = address
                            newTradesman.email = email
                            newTradesman.points = Int32(points)
                            newTradesman.badges = badges as NSArray
                            newTradesman.jobCompletionStreak = Int32(jobCompletionStreak)
                            
                            print("Added tradesman: \(firstName) with role: \(role)")
                        }
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
            // Ensure badges is initialized as a mutable Swift array
            var badgesArray = (tradesman.badges as? [String]) ?? []
            
            // Add the badge if it doesn't already exist
            if !badgesArray.contains(badge) {
                badgesArray.append(badge)
                print("Badge earned: \(badge) by \(tradesman.name ?? "Unknown")")
            }
            
            // Assign the modified array back to tradesman.badges as NSArray
            tradesman.badges = badgesArray as NSArray
            
            // Save the context
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

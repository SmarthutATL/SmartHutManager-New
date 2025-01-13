import SwiftUI
import CoreData
import FirebaseFirestore
import Foundation

class TradesmenManager {
    static let shared = TradesmenManager()
    
    private let firestore = Firestore.firestore()
    
    // MARK: - Helper Functions
    private func normalizeEmail(_ email: String) -> String {
        return email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Assign Missing IDs
        func assignMissingIds(context: NSManagedObjectContext) {
            let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()

            do {
                let tradesmen = try context.fetch(fetchRequest)

                context.perform {
                    for tradesman in tradesmen {
                        if tradesman.id == nil || tradesman.id?.isEmpty == true {
                            tradesman.id = UUID().uuidString // Assign a unique string ID
                            print("Assigned new UUID for tradesman: \(tradesman.name ?? "Unknown")")
                        }
                    }

                    do {
                        try context.save()
                        print("All missing IDs assigned successfully.")
                    } catch {
                        print("Failed to save context while assigning IDs: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("Failed to fetch tradesmen for ID assignment: \(error.localizedDescription)")
            }
        }
        
    // MARK: - Sync Tradesmen from Firestore to Core Data
    func syncTradesmen(context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
        fetchTradesmen(context: context) { existingTradesmen in
            self.firestore.collection("tradesmen").getDocuments { tradesmenSnapshot, tradesmenError in
                if let tradesmenError = tradesmenError {
                    completion(tradesmenError)
                    return
                }

                guard let tradesmenDocuments = tradesmenSnapshot?.documents else {
                    completion(nil)
                    return
                }

                let dispatchGroup = DispatchGroup()

                context.perform {
                    for tradesmanDocument in tradesmenDocuments {
                        let tradesmanData = tradesmanDocument.data()

                        guard let email = tradesmanData["email"] as? String else {
                            print("Tradesman missing email, skipping...")
                            continue
                        }

                        dispatchGroup.enter()

                        self.firestore.collection("users").whereField("email", isEqualTo: email).getDocuments { userSnapshot, userError in
                            if let userError = userError {
                                print("Error fetching user data for email \(email): \(userError.localizedDescription)")
                                dispatchGroup.leave()
                                return
                            }

                            guard let userDocument = userSnapshot?.documents.first else {
                                print("No matching user found for email: \(email)")
                                dispatchGroup.leave()
                                return
                            }

                            let userData = userDocument.data()
                            let firestoreName = userData["firstName"] as? String ?? "Unknown Name"
                            let role = userData["role"] as? String ?? "Unknown Role"
                            let firestoreJobTitle = tradesmanData["jobTitle"] as? String ?? role
                            let firestorePhoneNumber = tradesmanData["phoneNumber"] as? String
                            let firestoreAddress = tradesmanData["address"] as? String
                            let firestorePoints = tradesmanData["points"] as? Int ?? 0
                            let firestoreBadges = tradesmanData["badges"] as? [String] ?? []
                            let firestoreJobCompletionStreak = tradesmanData["jobCompletionStreak"] as? Int ?? 0

                            if let existingTradesman = existingTradesmen.first(where: { $0.email?.lowercased() == email.lowercased() }) {
                                // Compare each field to avoid overwriting local changes
                                if existingTradesman.name != firestoreName {
                                    print("Skipping name update for \(email). Local: \(existingTradesman.name ?? ""), Firestore: \(firestoreName)")
                                } else {
                                    existingTradesman.name = firestoreName
                                }

                                existingTradesman.jobTitle = firestoreJobTitle
                                existingTradesman.phoneNumber = existingTradesman.phoneNumber ?? firestorePhoneNumber
                                existingTradesman.address = existingTradesman.address ?? firestoreAddress
                                existingTradesman.email = email.lowercased()
                                existingTradesman.points = Int32(firestorePoints)
                                existingTradesman.badges = firestoreBadges as NSArray
                                existingTradesman.jobCompletionStreak = Int32(firestoreJobCompletionStreak)

                                print("Updated tradesman: \(firestoreName) with role: \(role)")
                            } else {
                                // Add new tradesman to Core Data
                                let newTradesman = Tradesmen(context: context)
                                newTradesman.name = firestoreName
                                newTradesman.jobTitle = firestoreJobTitle
                                newTradesman.phoneNumber = firestorePhoneNumber
                                newTradesman.address = firestoreAddress
                                newTradesman.email = email.lowercased()
                                newTradesman.points = Int32(firestorePoints)
                                newTradesman.badges = firestoreBadges as NSArray
                                newTradesman.jobCompletionStreak = Int32(firestoreJobCompletionStreak)

                                print("Added tradesman: \(firestoreName) with role: \(role)")
                            }

                            dispatchGroup.leave()
                        }
                    }

                    dispatchGroup.notify(queue: .main) {
                        do {
                            try context.save()
                            completion(nil)
                            print("All tradesmen synced and saved successfully.")
                        } catch {
                            completion(error)
                            print("Error saving tradesmen: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    // MARK: - Fetch Tradesmen from Core Data with Completion Handler
    func fetchTradesmen(context: NSManagedObjectContext, completion: @escaping ([Tradesmen]) -> Void) {
        context.perform {
            // Ensure the fetch request specifies the Tradesmen entity
            let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            do {
                let tradesmen = try context.fetch(fetchRequest)
                completion(tradesmen)
            } catch {
                print("Error fetching tradesmen: \(error.localizedDescription)")
                completion([])
            }
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
        guard let email = tradesman.email else { return }

        let data: [String: Any] = [
            "name": tradesman.name ?? "",
            "jobTitle": tradesman.jobTitle ?? "",
            "phoneNumber": tradesman.phoneNumber ?? "",
            "address": tradesman.address ?? "",
            "email": email,
            "points": tradesman.points,
            "badges": tradesman.badges ?? [],
            "jobCompletionStreak": tradesman.jobCompletionStreak
        ]

        firestore.collection("tradesmen").document(email).setData(data) { error in
            if let error = error {
                print("Failed to save tradesman to Firestore: \(error.localizedDescription)")
            } else {
                print("Tradesman saved to Firestore successfully.")
            }
        }
    }
    func deleteTradesman(_ tradesman: Tradesmen, context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
          // Delete from Firestore
          if let email = tradesman.email {
              firestore.collection("tradesmen").document(email).delete { error in
                  if let error = error {
                      print("Failed to delete tradesman from Firestore: \(error.localizedDescription)")
                      completion(false)
                  } else {
                      print("Tradesman deleted from Firestore.")
                      
                      // Delete from Core Data
                      context.perform {
                          context.delete(tradesman)
                          do {
                              try context.save()
                              print("Tradesman deleted from Core Data.")
                              completion(true)
                          } catch {
                              print("Failed to delete tradesman from Core Data: \(error.localizedDescription)")
                              completion(false)
                          }
                      }
                  }
              }
          } else {
              print("Tradesman email is missing. Skipping Firestore deletion.")
              completion(false)
          }
      }
}

import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Foundation
import CoreData

class GamificationManager {
    static let shared = GamificationManager()
    
    // Fetch leaderboard data directly from Core Data
    func getLeaderboardData(context: NSManagedObjectContext) -> [String: Int] {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        var leaderboard: [String: Int] = [:]

        do {
            let tradesmen = try context.fetch(fetchRequest)
            for tradesman in tradesmen {
                if let name = tradesman.name {
                    leaderboard[name] = Int(tradesman.points)
                }
            }
        } catch {
            print("Failed to fetch leaderboard data: \(error.localizedDescription)")
        }

        return leaderboard
    }

    // Fetch badges directly from Core Data
    func getBadges(for user: String, context: NSManagedObjectContext) -> [String] {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first, let badges = tradesman.badges {
                return badges
            }
        } catch {
            print("Failed to fetch badges for \(user): \(error.localizedDescription)")
        }

        return []
    }

    func addPoints(to user: String, points: Int, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first {
                tradesman.points += Int32(points)
                try context.save()
            }
        } catch {
            print("Failed to add points for \(user): \(error.localizedDescription)")
        }
    }

    func earnBadge(for user: String, badge: String, context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Tradesmen> = Tradesmen.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", user)

        do {
            let results = try context.fetch(fetchRequest)
            if let tradesman = results.first {
                if tradesman.badges == nil {
                    tradesman.badges = []
                }
                if !(tradesman.badges?.contains(badge) ?? false) {
                    tradesman.badges?.append(badge)
                    try context.save()
                    print("Badge \(badge) added for \(user).")
                }
            }
        } catch {
            print("Failed to assign badge \(badge) to \(user): \(error.localizedDescription)")
        }
    }
}
